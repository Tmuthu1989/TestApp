class AddOdooTypeToPart < ActiveRecord::Migration[7.0]
  def change
    add_column :parts, :odoo_type, :string
    add_column :bom_headers, :odoo_type, :string
    add_column :bom_components, :odoo_type, :string
    add_column :documents, :odoo_type, :string
  end
end
