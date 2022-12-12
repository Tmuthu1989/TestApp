class CreateDocumentUploads < ActiveRecord::Migration[7.0]
  def change
    create_table :document_uploads, id: :uuid do |t|
      t.references :xml_file, null: false, foreign_key: true, type: :uuid
      t.references :document, null: false, foreign_key: true, type: :uuid
      t.string :document_number
      t.string :number
      t.string :part_number
      t.string :odoo_part_number
      t.string :file_name
      t.string :file_path
      t.string :status, default: AppConstants::FILE_STATUS[:pending]
      t.jsonb :error
      t.boolean :is_odoo_upload

      t.timestamps
    end
  end
end
