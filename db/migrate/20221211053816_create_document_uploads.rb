class CreateDocumentUploads < ActiveRecord::Migration[7.0]
  def change
    create_table :document_uploads, id: :uuid do |t|
      t.references :xml_file, null: false, foreign_key: true, type: :uuid
      t.string :document_number
      t.string :part_number
      t.jsonb :error

      t.timestamps
    end
  end
end
