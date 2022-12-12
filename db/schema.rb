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

ActiveRecord::Schema[7.0].define(version: 2022_12_12_210538) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.jsonb "error", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "odoo_type"
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
    t.jsonb "error", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "odoo_type"
    t.index ["bom_type", "number"], name: "index_bom_headers_on_bom_type_and_number"
    t.index ["bom_type", "odoo_part_number", "number"], name: "index_bom_headers_on_bom_type_and_odoo_part_number_and_number"
    t.index ["bom_type", "odoo_part_number"], name: "index_bom_headers_on_bom_type_and_odoo_part_number"
    t.index ["bom_type"], name: "index_bom_headers_on_bom_type"
    t.index ["number"], name: "index_bom_headers_on_number"
    t.index ["odoo_part_number"], name: "index_bom_headers_on_odoo_part_number"
    t.index ["xml_file_id"], name: "index_bom_headers_on_xml_file_id"
  end

  create_table "document_uploads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "xml_file_id", null: false
    t.uuid "document_id", null: false
    t.string "document_number"
    t.string "number"
    t.string "part_number"
    t.string "odoo_part_number"
    t.string "file_name"
    t.string "file_path"
    t.string "status", default: "Pending"
    t.jsonb "error"
    t.boolean "is_odoo_upload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_document_uploads_on_document_id"
    t.index ["xml_file_id"], name: "index_document_uploads_on_xml_file_id"
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
    t.string "odoo_type"
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
    t.string "odoo_type"
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

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.jsonb "permissions"
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
    t.text "logo"
    t.string "part_name_language", default: "name_a"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "first_name"
    t.string "last_name"
    t.boolean "is_super_admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "role_id", null: false
    t.string "default_password"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bom_components", "bom_headers"
  add_foreign_key "bom_components", "xml_files"
  add_foreign_key "bom_headers", "xml_files"
  add_foreign_key "document_uploads", "documents"
  add_foreign_key "document_uploads", "xml_files"
  add_foreign_key "documents", "xml_files"
  add_foreign_key "http_requests", "xml_files"
  add_foreign_key "parts", "xml_files"
  add_foreign_key "users", "roles"
end
