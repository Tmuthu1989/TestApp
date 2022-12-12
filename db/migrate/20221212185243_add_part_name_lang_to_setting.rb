class AddPartNameLangToSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :part_name_language, :string, default: "name_a"
  end
end
