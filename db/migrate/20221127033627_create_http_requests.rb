class CreateHttpRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :http_requests, id: :uuid do |t|
      t.string :xml_file_id
      t.string :req_url
      t.jsonb :req_body, default: {}
      t.jsonb :res_body, default: {}
      t.jsonb :error, default: {}

      t.timestamps
    end
  end
end
