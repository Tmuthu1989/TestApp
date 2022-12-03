class AddDeleteFileAndRenameDocumentToSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :delete_file, :boolean, default: false
    add_column :settings, :rename_document, :boolean, default: true
  end
end
