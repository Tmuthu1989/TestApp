class CreateBomHeaders < ActiveRecord::Migration[7.0]
  def change
    create_table :bom_headers, id: :uuid do |t|
      t.string :xml_file_id
      t.string :bom_type
      t.string :processed_by
      t.string :number
      t.string :odoo_part_number
      t.string :status, default: AppConstants::FILE_STATUS[:pending]
      t.jsonb :json_obj, default: {}
      t.text :xml_content

      t.timestamps
    end
  end
end
