class BomHeader < ApplicationRecord
	belongs_to :xml_file
	has_many :bom_components, dependent: :destroy

	scope :pending, -> { where.not(status: AppConstants::FILE_STATUS[:success]) }
  scope :success, -> { where(status: AppConstants::FILE_STATUS[:success]) }
  scope :added, -> { where(bom_type: "AddedBOMs") }
  scope :changed, -> { where(bom_type: "ChangedBOMs") }
  scope :unchanged, -> { where(bom_type: "UnchangedBOMs") }
  scope :deleted, -> { where(bom_type: "DeletedBOMs") }

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
			@odoo_service = OdooService.new(@setting, xml_file.id)
			bom_headers = xml_file.bom_headers.pending.includes(:bom_components).group_by(&:bom_type)
			process_added_boms(bom_headers["AddedBOMs"])		
			# process_updated_boms(bom_headers["AddedBOMs"])		
			# process_deleted_boms(bom_headers["AddedBOMs"])		
	end

	def self.process_added_boms(bom_headers)
		boms = []
		bom_headers.each do |bom_header|
			bom_components = bom_header.bom_components.added
			deleted_components = bom_header.bom_components.deleted_inwork
			empty_part_components = deleted_components.where(odoo_part_number: nil).pluck(:part_number)
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
				end
			end
			boms << {
				part: bom_header.odoo_part_number,
				child_ids: child_ids
			}
		end
		result = @odoo_service.create_bom_components(boms)
		BomHeader.where(id: bom_headers.map { |e| e.id }).update_all(status: AppConstants::FILE_STATUS[:success])
	end

	def self.process_updated_boms(bom_headers)
		
	end

	def self.process_deleted_boms(bom_headers)
		
	end
end
