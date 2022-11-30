class CreateBomComponents < ActiveRecord::Migration[7.0]
  def change
    create_table :bom_components, id: :uuid do |t|
      t.string :xml_file_id
      t.string :bom_header_id
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
      t.timestamps
    end
  end
end
