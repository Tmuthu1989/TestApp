class AddDocumentsFolderToSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :documents_folder, :string
  end
end
