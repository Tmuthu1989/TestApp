class AddIndexToParts < ActiveRecord::Migration[7.0]
  def change
    add_index :parts, :part_number
    add_index :parts, :part_name
    add_index :parts, :odoo_part_number
    add_index :parts, [:part_name, :part_number]
    add_index :parts, [:odoo_part_number, :part_number]
    add_index :parts, [:odoo_part_number, :part_name]
    add_index :parts, [:odoo_part_number, :part_name, :part_number]
  end
end
