class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.string :user_id
      t.string :plan_id
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end
