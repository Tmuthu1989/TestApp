class AddAmountToSubscription < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :amount, :float
  end
end
