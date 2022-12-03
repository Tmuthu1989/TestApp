class CreateHttpRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :http_requests, id: :uuid do |t|
      t.references :xml_file, null: false, foreign_key: true, type: :uuid
      t.string :request_type
      t.string :req_url
      t.jsonb :req_body, default: {}
      t.jsonb :res_body, default: {}
      t.jsonb :error, default: {}
      t.index :req_url
      t.timestamps
    end
  end
end
