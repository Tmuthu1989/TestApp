class CreateSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :settings, id: :uuid do |t|
      t.string :app_name
      t.string :xml_files_path

      t.timestamps
    end
  end
end
