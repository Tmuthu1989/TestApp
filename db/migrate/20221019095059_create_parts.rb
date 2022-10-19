class CreateParts < ActiveRecord::Migration[7.0]
  def change
    create_table :parts, id: :uuid do |t|
      t.references :xml_file, null: false, foreign_key: true, type: :uuid
      t.string :part_number
      t.string :part_name
      t.string :part_type
      t.jsonb :part_json, default: "{}"
      t.text :part_xml
      t.text :error
      t.string :status, default: AppConstants::FILE_STATUS[:pending]
      t.timestamps
    end
  end
end
