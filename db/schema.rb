# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_12_06_105942) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "bom_components", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "xml_file_id", null: false
    t.uuid "bom_header_id", null: false
    t.string "bom_component_type"
    t.string "processed_by"
    t.string "part_number"
    t.string "part_state"
    t.string "assembly_part_number"
    t.string "odoo_part_number"
    t.float "quantity"
    t.string "unit"
    t.string "status", default: "Pending"
    t.jsonb "json_obj", default: {}
    t.text "xml_content"
    t.jsonb "odoo_body", default: {}
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assembly_part_number"], name: "index_bom_components_on_assembly_part_number"
    t.index ["bom_component_type", "assembly_part_number", "part_number"], name: "index_type_xml_assembly_part"
    t.index ["bom_component_type", "assembly_part_number"], name: "index_type_assembly_part"
    t.index ["bom_component_type", "odoo_part_number", "part_number"], name: "index_type_odoo_part_number"
    t.index ["bom_component_type", "odoo_part_number"], name: "index_bom_components_on_bom_component_type_and_odoo_part_number"
    t.index ["bom_component_type", "part_number"], name: "index_bom_components_on_bom_component_type_and_part_number"
    t.index ["bom_component_type", "xml_file_id", "bom_header_id"], name: "index_type_xml_header"
    t.index ["bom_component_type", "xml_file_id"], name: "index_bom_components_on_bom_component_type_and_xml_file_id"
    t.index ["bom_component_type"], name: "index_bom_components_on_bom_component_type"
    t.index ["bom_header_id"], name: "index_bom_components_on_bom_header_id"
    t.index ["odoo_part_number"], name: "index_bom_components_on_odoo_part_number"
    t.index ["part_number"], name: "index_bom_components_on_part_number"
    t.index ["xml_file_id"], name: "index_bom_components_on_xml_file_id"
  end

  create_table "bom_headers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "xml_file_id", null: false
    t.string "bom_type"
    t.string "processed_by"
    t.string "number"
    t.string "odoo_part_number"
    t.string "status", default: "Pending"
    t.jsonb "json_obj", default: {}
    t.text "xml_content"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bom_type", "number"], name: "index_bom_headers_on_bom_type_and_number"
    t.index ["bom_type", "odoo_part_number", "number"], name: "index_bom_headers_on_bom_type_and_odoo_part_number_and_number"
    t.index ["bom_type", "odoo_part_number"], name: "index_bom_headers_on_bom_type_and_odoo_part_number"
    t.index ["bom_type"], name: "index_bom_headers_on_bom_type"
    t.index ["number"], name: "index_bom_headers_on_number"
    t.index ["odoo_part_number"], name: "index_bom_headers_on_odoo_part_number"
    t.index ["xml_file_id"], name: "index_bom_headers_on_xml_file_id"
  end

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "doc_type"
    t.uuid "xml_file_id", null: false
    t.string "number"
    t.string "name"
    t.string "document_type"
    t.string "document_number"
    t.string "document_url"
    t.string "odoo_part_number"
    t.string "part_number"
    t.string "status", default: "Pending"
    t.jsonb "error", default: {}
    t.text "xml_content"
    t.jsonb "json_obj", default: {}
    t.jsonb "odoo_body", default: {}
    t.string "original_file_name"
    t.string "new_file_name"
    t.string "extention"
    t.string "new_extention"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["xml_file_id"], name: "index_documents_on_xml_file_id"
  end

  create_table "http_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "xml_file_id", null: false
    t.string "request_type"
    t.string "req_url"
    t.jsonb "req_body", default: {}
    t.jsonb "res_body", default: {}
    t.jsonb "error", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["req_url"], name: "index_http_requests_on_req_url"
    t.index ["xml_file_id"], name: "index_http_requests_on_xml_file_id"
  end

  create_table "parts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "xml_file_id", null: false
    t.string "part_number"
    t.string "part_name"
    t.string "part_type"
    t.jsonb "part_json", default: "{}"
    t.text "part_xml"
    t.jsonb "error"
    t.string "status", default: "Pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "odoo_body", default: {}
    t.string "odoo_part_number"
    t.string "created_by"
    t.jsonb "transaction_obj", default: {}
    t.string "processed_by"
    t.string "state"
    t.index ["odoo_part_number", "part_name", "part_number"], name: "index_parts_on_odoo_part_number_and_part_name_and_part_number"
    t.index ["odoo_part_number", "part_name"], name: "index_parts_on_odoo_part_number_and_part_name"
    t.index ["odoo_part_number", "part_number"], name: "index_parts_on_odoo_part_number_and_part_number"
    t.index ["odoo_part_number"], name: "index_parts_on_odoo_part_number"
    t.index ["part_name", "part_number"], name: "index_parts_on_part_name_and_part_number"
    t.index ["part_name"], name: "index_parts_on_part_name"
    t.index ["part_number"], name: "index_parts_on_part_number"
    t.index ["xml_file_id"], name: "index_parts_on_xml_file_id"
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "app_name"
    t.string "xml_files_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "api_config", default: {}
    t.text "current_api_key"
    t.string "access_token"
    t.string "cookie"
    t.boolean "delete_file", default: false
    t.boolean "rename_document", default: true
    t.string "documents_folder"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "xml_files", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "file_name"
    t.string "file_path"
    t.text "file_content"
    t.text "file_error"
    t.string "date"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "json_obj", default: {}
  end

  add_foreign_key "bom_components", "bom_headers"
  add_foreign_key "bom_components", "xml_files"
  add_foreign_key "bom_headers", "xml_files"
  add_foreign_key "documents", "xml_files"
  add_foreign_key "http_requests", "xml_files"
  add_foreign_key "parts", "xml_files"
end
