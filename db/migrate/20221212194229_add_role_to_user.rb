class AddRoleToUser < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :role, null: false, foreign_key: true, type: :uuid
  end
end
