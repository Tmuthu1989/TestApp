class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents, id: :uuid do |t|
      t.string :doc_type
      t.references :xml_file, null: false, foreign_key: true, type: :uuid
      t.string :number
      t.string :name
      t.string :document_type
      t.string :document_number
      t.string :document_url
      t.string :odoo_part_number
      t.string :part_number
      t.string :status, default: AppConstants::FILE_STATUS[:pending]
      t.jsonb :error, default: {}
      t.text :xml_content
      t.jsonb :json_obj, default: {}
      t.jsonb :odoo_body, default: {}
      t.string :original_file_name
      t.string :new_file_name
      t.string :extention
      t.string :new_extention
      t.timestamps
    end
  end
end
