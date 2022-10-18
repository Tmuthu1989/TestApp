class CreateXmlFiles < ActiveRecord::Migration[7.0]
  def change
    create_table :xml_files, id: :uuid do |t|
      t.string :file_name
      t.string :file_path
      t.text :file_content, limit: 100.megabytes - 1
      t.text :file_error
      t.string :date
      t.string :status

      t.timestamps
    end
  end
end
