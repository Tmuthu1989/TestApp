class AddJsonObjToXmlFile < ActiveRecord::Migration[7.0]
  def change
    add_column :xml_files, :json_obj, :jsonb, default: {}
  end
end
