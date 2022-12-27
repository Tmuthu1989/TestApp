class BomHeader < ApplicationRecord
	belongs_to :xml_file
	has_many :bom_components, dependent: :destroy

	scope :pending, -> { where.not(status: AppConstants::FILE_STATUS[:success]) }
  scope :success, -> { where(status: AppConstants::FILE_STATUS[:success]) }
  scope :added, -> { where(bom_type: "AddedBOMs") }
  scope :changed, -> { where(bom_type: "ChangedBOMs") }
  scope :unchanged, -> { where(bom_type: "UnchangedBOMs") }
  scope :deleted, -> { where(bom_type: "DeletedBOMs") }

  accepts_nested_attributes_for :bom_components, reject_if: :all_blank, allow_destroy: true

  def pending?
    status != AppConstants::FILE_STATUS[:success]
  end

	def self.load_bom_headers(xml_file)
		json_obj = xml_file.json_obj
    if json_obj
      json_content = json_obj["COLLECTION"]
      transaction_obj = json_content["Release"]["Transaction"]
      parts_json = xml_file.parts.pluck(:part_name, :odoo_part_number).to_h
      ["AddedBOMs", "ChangedBOMs", "UnchangedBOMs", "DeletedBOMs"].each do |type|
      	if json_content[type].present? && json_content[type]["BOMHeader"].present?
          bom_headers = json_content[type]["BOMHeader"]
          bom_headers = [bom_headers] if bom_headers.class.to_s != "Array"
          bom_headers.each do |bom_header|
            xml_file.bom_headers.create(bom_type: type, number: bom_header["Number"], json_obj: bom_header, xml_content: bom_header.to_xml(root: :BOMHeader), odoo_part_number: parts_json[bom_header["Number"]])
          end
        end
      end
    end
	end

	def self.process_boms(xml_file)
		begin
      @setting = Setting.last
      @xml_file = xml_file
			@odoo_service = OdooService.new(@setting, xml_file.id)
			added_bom_headers = xml_file.bom_headers.pending.added.includes(:bom_components)
			changed_bom_headers = xml_file.bom_headers.pending.includes(:bom_components).where(bom_type: ["ChangedBOMs", "UnchangedBOMs"])
			deleted_boms = xml_file.bom_headers.deleted
			process_added_boms(xml_file.id, added_bom_headers)		
			process_updated_boms(xml_file.id, changed_bom_headers)		
			process_deleted_boms(xml_file.id, deleted_boms)
		rescue StandardError => e
      error = {
        error_type: "StandardError",
        title: e,
        message: e.message,
        backtrace: e.backtrace
      }
      HttpRequest.create(error: error, xml_file_id: xml_file.id)
    end		
	end

	def self.process_bom(bom_header)
		@setting = Setting.last
		error = {}
		@odoo_service = OdooService.new(@setting, bom_header.xml_file_id)
		if bom_header.bom_type == "AddedBOMs"
			result = BomHeader.process_added_boms(bom_header.xml_file_id, [bom_header])
		elsif bom_header.bom_type != "DeletedBOMs"
			added_result, result = BomHeader.process_updated_boms(bom_header.xml_file_id, [bom_header])
		else
			result = BomHeader.process_deleted_boms(bom_header.xml_file_id, [bom_header])
		end
	end

	def self.process_added_boms(xml_file_id, bom_headers)
		boms = []
		if bom_headers.present?
			bom_component_ids = []
			del_bom_component_ids = []
			bom_header_ids = []
			bom_headers.each do |bom_header|
				bom_components = bom_header.bom_components.added
				deleted_components = bom_header.bom_components.deleted.where(part_state: "INWORK")
				empty_part_components = deleted_components.map { |comp| comp.part_number if comp.odoo_part_number.blank? }.compact
				odoo_part_numbers = {}
				if empty_part_components.present?
					search_result = @odoo_service.get_products(empty_part_components)
					search_result.each do |result|
						odoo_part_numbers[result.part] = result.default_code
					end
				end
				bom_components += deleted_components
				child_ids = []
				bom_components.each do |bom_component|
					odoo_part_number = bom_component.odoo_part_number || odoo_part_numbers[bom_component.part_number]
					if odoo_part_number.present?
						child_ids << {
							qty: bom_component.quantity,
							part: odoo_part_number
						}
						bom_component.update(odoo_part_number: odoo_part_number)
						if bom_component.bom_component_type === "DeletedBOMComponents"
							del_bom_component_ids << bom_component.id
						else
							bom_component_ids << bom_component.id
						end
					end
				end
				boms << {
					part: bom_header.odoo_part_number,
					child_ids: child_ids
				}
				bom_header_ids << bom_header.id
			end
			result, error = @odoo_service.create_boms(boms)
			if result.present?
				bom_header_ids, bom_component_ids, del_bom_component_ids = self.update_error_list(xml_file_id, [bom_header_ids, bom_component_ids, del_bom_component_ids], result, ["AddedBOMs", "AddedBOMComponents", "Added from DeletedBOMComponents"])
				BomHeader.where(id: bom_header_ids).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "AddedBOMs") if bom_header_ids.present?
				BomComponent.where(id: bom_component_ids).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "AddedBOMComponents", odoo_type: "Add") if bom_component_ids.present?
				BomComponent.where(id: del_bom_component_ids).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Added from DeletedBOMComponents", odoo_type: "Add") if del_bom_component_ids.present?
			end
			result
		end
	end

	def self.process_updated_boms(xml_file_id, bom_headers)
		update_boms = []
		create_boms = []
		if bom_headers.present?
			bom_search_result = {}
			@odoo_service.search_boms(bom_headers.map { |e| e.odoo_part_number }).map { |result| 
				bom_search_result[result.part] ||= {}
				result.child_ids.map { |child| 
					bom_search_result[result.part][child.part] = child.qty
				}
			}
			bom_header_ids = []
			added_bom_header_ids = []
			error_comp_ids = []
			bom_component_ids = []
			added_component_ids = []
			bom_headers.each do |bom_header|
				bom = bom_header
				bom_components = bom_header.bom_components.where(bom_component_type: ["AddedBOMComponents", "ChangedBOMComponents", "UnchangedBOMComponents"])

				deleted_components = bom_header.bom_components.where(bom_component_type: "DeletedBOMComponents").where.not(part_state: "INWORK", odoo_part_number: nil)
				del_child_ids = deleted_components.pluck(:odoo_part_number).compact
				if bom.odoo_part_number && del_child_ids.present?
					delele_result = @odoo_service.delete_bom_components([bom.odoo_part_number], del_child_ids)
					if delele_result[1].present?
						deleted_components.update_all(error: {error: delele_result[1]})
						err = bom_header.error
						deleted_components.each do |comp|
							err[comp.odoo_part_number] = delele_result[1]
						end
						err["message"] = "#{err.keys} having the following error: #{delele_result[1]}"
						bom_header.update(error: err)
						error_comp_ids << bom_header.id
					else
						deleted_components.update_all(status: AppConstants::FILE_STATUS[:success])
					end
				end
				if bom.odoo_part_number.present?
					added_bom = {
						part: bom.odoo_part_number,
						child_ids: []
					}
					update_bom = {
						part: bom.odoo_part_number,
						child_ids: []
					}
					search_childs = bom_search_result[bom.odoo_part_number] || {}
					bom_components.each do |bom_component|
						search_child_quantity = search_childs[bom_component.odoo_part_number]
						if search_child_quantity.present?
							if bom_component.quantity != search_child_quantity
								update_bom[:child_ids] << {
									part: bom_component.odoo_part_number,
									qty: bom_component.quantity
								}
								bom_component_ids = bom_component.id
								bom_header_ids << bom_header.id
							end
						else
							added_bom[:child_ids] << {
								part: bom_component.odoo_part_number,
								qty: bom_component.quantity
							}
							added_bom_header_ids << bom_header.id
							added_component_ids << bom_component.id
						end
					end
					create_boms << added_bom if added_bom[:child_ids].present?
					update_boms << update_bom if update_bom[:child_ids].present?
				end
			end
			if create_boms.present?
				add_result, error = @odoo_service.create_boms(create_boms)
				added_bom_header_ids = added_bom_header_ids - error_comp_ids
				added_bom_header_ids, added_component_ids, del_bom_component_ids = self.update_error_list(xml_file_id, [added_bom_header_ids, added_component_ids, []], add_result, ["Added by UpdateBOMs", "Added from UpdateBOMComponents", ""])
				BomHeader.where(id: added_bom_header_ids.uniq).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Added by UpdateBOMs", odoo_type: "Add") if add_result && added_bom_header_ids.present?
				BomComponent.where(id: added_component_ids).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Added from UpdateBOMComponents", odoo_type: "Add") if add_result && added_component_ids.present?
			end

			if update_boms.present?
				update_result, error = @odoo_service.update_boms(update_boms)
				bom_header_ids = bom_header_ids - error_comp_ids
				bom_header_ids, bom_component_ids, del_bom_component_ids = self.update_error_list(xml_file_id, [bom_header_ids, bom_component_ids, []], update_result, ["UpdateBOMs", "UpdateBOMComponents", ""])
				BomHeader.where(id: bom_header_ids.uniq).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "UpdateBOMs", odoo_type: "Update") if update_result && bom_header_ids.present?
				BomComponent.where(id: bom_component_ids).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "UpdateBOMComponents", odoo_type: "Update") if update_result && bom_component_ids.present?
			end
			[add_result, update_result]
		end
	end

	def self.process_deleted_boms(xml_file_id, bom_headers)
		if bom_headers.present?
			bom_components = BomComponent.deleted.where(bom_header_id: bom_headers.pluck(:id)).where.not(odoo_part_number: nil)
			result, error = @odoo_service.deleted_boms(bom_headers.pluck(:odoo_part_number).compact, bom_components.pluck(:odoo_part_number).compact)
			status, error_msg = AppConstants::FILE_STATUS[:success], {}
			
			if result.result.error_list.present?
				headers = result.result.error_list.map { |e| e["header_list"] }.flatter.compact
				headers.each_with_index do |header, i|
					error_msg = result.result.logs[i]
					error_headers = bom_headers.where(odoo_part_number: header)
					error_headers.update_all(status: AppConstants::FILE_STATUS[:success], odoo_type: "Delete", error: {message: error_msg})
					bom_components.where(bom_header_id: error_headers.pluck(:id)).update_all(status: AppConstants::FILE_STATUS[:success], odoo_type: "Delete", error: {message: error_msg})
				end
			else
				bom_headers.update(status: AppConstants::FILE_STATUS[:success], odoo_type: "Delete")
				bom_components.update(status: AppConstants::FILE_STATUS[:success], odoo_type: "Delete")
			end
			result
		end
	end


	def self.update_error_list(xml_file_id, boms, response, processed_by)
    bom_headers, bom_components, del_bom_components = boms
    header_processed_by, component_processed_by, del_component_processed_by = processed_by
    if response.result.error_list.present? && response.result.error_list["header_list"].present?
    	headers = BomHeader.includes(:bom_components).where(xml_file_id: xml_file_id, odoo_part_number: response.result.error_list["header_list"])
    	components = {}
    	BomComponent.where(xml_file_id: xml_file_id, odoo_part_number: response.result.error_list["child_ids"]).map { |e| components[e.odoo_part_number] = e }
    	headers.each do |header|
    		bom_headers.delete(header.id)
    		errors = []
    		child_ids = components.keys & header.bom_component_ids
    		child_ids.each do |child_id|
    			child = components[child_id]
    			if child.present?
    				error_msg = response.result.error_list["logs"].find{|e| e.include?("#{child.odoo_part_number}:")}
    				child.update(status: AppConstants::FILE_STATUS[:failed], error: {message: error_msg}, processed_by: child.is_deleted? ? del_component_processed_by : component_processed_by)
    				errors << error_msg
    				bom_components.delete(child_id)
    				del_bom_components.delete(child_id)
    			end
    		end
    		header.update(status: AppConstants::FILE_STATUS[:failed], error: {message: errors.join(", ")}, processed_by: header_processed_by)
    	end
    end
    [bom_headers, bom_components, del_bom_components]
  end
end
