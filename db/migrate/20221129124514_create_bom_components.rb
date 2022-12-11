class CreateBomComponents < ActiveRecord::Migration[7.0]
  def change
    create_table :bom_components, id: :uuid do |t|
      t.references :xml_file, null: false, foreign_key: true, type: :uuid
      t.references :bom_header, null: false, foreign_key: true, type: :uuid
      t.string :bom_component_type
      t.string :processed_by
      t.string :part_number
      t.string :part_state
      t.string :assembly_part_number
      t.string :odoo_part_number
      t.float :quantity
      t.string :unit
      t.string :status, default: AppConstants::FILE_STATUS[:pending]
      t.jsonb :json_obj, default: {}
      t.text :xml_content
      t.jsonb :odoo_body, default: {}
      t.jsonb :error, default: {}
      t.index :bom_component_type
      t.index :part_number
      t.index :assembly_part_number
      t.index :odoo_part_number
      t.index [:bom_component_type, :xml_file_id]
      t.index [:bom_component_type, :xml_file_id, :bom_header_id], name: "index_type_xml_header"
      t.index [:bom_component_type, :part_number]
      t.index [:bom_component_type, :assembly_part_number], name: "index_type_assembly_part"
      t.index [:bom_component_type, :assembly_part_number, :part_number], name: "index_type_xml_assembly_part"
      t.index [:bom_component_type, :odoo_part_number]
      t.index [:bom_component_type, :odoo_part_number, :part_number], name: "index_type_odoo_part_number"

      t.timestamps
    end
  end
end
