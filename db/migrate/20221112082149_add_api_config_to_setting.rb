class AddApiConfigToSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :api_config, :json, default: {}
    add_column :settings, :current_api_key, :text
  end
end
