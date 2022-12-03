class CreateBomHeaders < ActiveRecord::Migration[7.0]
  def change
    create_table :bom_headers, id: :uuid do |t|
      t.references :xml_file, null: false, foreign_key: true, type: :uuid
      t.string :bom_type
      t.string :processed_by
      t.string :number
      t.string :odoo_part_number
      t.string :status, default: AppConstants::FILE_STATUS[:pending]
      t.jsonb :json_obj, default: {}
      t.text :xml_content
      t.text :error
      t.index :bom_type
      t.index :number
      t.index :odoo_part_number
      t.index [:bom_type, :number]
      t.index [:bom_type, :odoo_part_number]
      t.index [:bom_type, :odoo_part_number, :number]

      t.timestamps
    end
  end
end
