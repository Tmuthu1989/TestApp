class AddAccessTokenToSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :access_token, :string
    add_column :settings, :cookie, :string
  end
end
