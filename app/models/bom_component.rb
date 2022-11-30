class BomComponent < ApplicationRecord
	belongs_to :bom_header
  scope :pending, -> { where.not(status: AppConstants::FILE_STATUS[:success]) }
  scope :success, -> { where(status: AppConstants::FILE_STATUS[:success]) }
  scope :added, -> { where(bom_component_type: "AddedBOMComponents") }
  scope :changed, -> { where(bom_component_type: "ChangedBOMComponents") }
  scope :unchanged, -> { where(bom_component_type: "UnchangedBOMComponents") }
  scope :deleted, -> { where(bom_component_type: "DeletedBOMComponents") }
  scope :deleted_inwork, -> { where(bom_component_type: "DeletedBOMs", part_state:"INWORK") }
  

	def self.load_bom_components(xml_file)
		json_obj = xml_file.json_obj
    if json_obj
      json_content = json_obj["COLLECTION"]
      transaction_obj = json_content["Release"]["Transaction"]
      bom_headers = xml_file.bom_headers.pluck(:number, :id).to_h
      parts_json = xml_file.parts.pluck(:part_name, :odoo_part_number).to_h
      parts_state_json = xml_file.parts.pluck(:part_name, :state).to_h
      ["AddedBOMComponents", "ChangedBOMComponents", "UnchangedBOMComponents", "DeletedBOMComponents"].each do |type|
      	if json_content[type].present? && json_content[type]["BOMComponent"].present?
          bom_components = json_content[type]["BOMComponent"]
          bom_components = [bom_components] if bom_components.class.to_s != "Array"
          bom_components.each do |bom_component|
            odoo_part_number = parts_json[bom_component["PartNumber"]]
            xml_file.bom_components.create(bom_component_type: type, bom_header_id: bom_headers[bom_component["AssemblyPartNumber"]], part_number: bom_component["PartNumber"], assembly_part_number: bom_component["AssemblyPartNumber"], json_obj: bom_component, xml_content: bom_component.to_xml(root: :BOMComponent), odoo_part_number: odoo_part_number, quantity: bom_component["Quantity"], unit: bom_component["Unit"], odoo_body: {part: odoo_part_number, qty: bom_component["Quantity"]}, part_state: parts_state_json[bom_component["PartNumber"]])
          end
        end
      end
    end
	end
end
