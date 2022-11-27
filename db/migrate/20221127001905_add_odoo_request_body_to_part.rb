class AddOdooRequestBodyToPart < ActiveRecord::Migration[7.0]
  def change
    change_table :parts, bulk: true do |t|
      t.jsonb  :odoo_body, default: {}
      t.string :odoo_part_number
      t.string :created_by
      t.jsonb :transaction_obj, default: {}
      t.string :processed_by
    end
  end
end
