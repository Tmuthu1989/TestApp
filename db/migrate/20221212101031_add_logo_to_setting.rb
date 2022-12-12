class AddLogoToSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :logo, :text
  end
end
