class AddStateToPart < ActiveRecord::Migration[7.0]
  def change
    add_column :parts, :state, :string
  end
end
