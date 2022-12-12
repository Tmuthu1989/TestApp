Setting.destroy_all
Setting.create(
	xml_files_path: "C:/xml_files", 
	app_name: "Read XML",
	documents_folder: "C:/documents",
	api_config: {
		"base_url" => "https://odoo-test.jungo.eu",
		"auth" => "/api/token",
		"product_list" => "/get/product_list",
		"product_creation" => "/api/product_create",
		"product_update" => "/api/product_update",
		"product_delete" => "/api/product_delete",
		"auth_login" => "admin",
		"auth_password" => "admin",
		"auth_db" => "odoo-test",
		"bom_search" => "/get/bom_list",
		"bom_create" => "/api/bom_part_create",
		"bom_update" => "/api/bom_part_update",
		"bom_delete" => "/api/bom_part_delete",
		"bom_component_delete" => "/api/delete_bom_component",
		"document_search" => "/api/document_search",
		"document_create" => "/api/part_doc_create",
		"document_delete" => "/api/document_delete",
		"document_upload" => "/api/product_image",
		"obs_url" => "https://obs.eu-de.otc.t-systems.com:443/windchill-odoo-doc-test"
	}
)
super_admin = Role.find_or_create_by(name: "Super Admin") do |t|
	t.settings = Role::READ_AND_WRITE
	t.xml_files = Role::READ_AND_WRITE
	t.parts = Role::READ_AND_WRITE
	t.boms = Role::READ_AND_WRITE
	t.documents = Role::READ_AND_WRITE
	t.document_uploads = Role::READ_AND_WRITE
	t.user_management = Role::READ_AND_WRITE
	t.roles = Role::READ_AND_WRITE
end

Role.find_or_create_by(name: "IT Admin") do |t|
	t.settings = Role::READ_AND_WRITE
	t.xml_files = Role::READ_AND_WRITE
	t.parts = Role::READ_AND_WRITE
	t.boms = Role::READ_AND_WRITE
	t.documents = Role::READ_AND_WRITE
	t.document_uploads = Role::READ_AND_WRITE
	t.user_management = Role::READ_AND_WRITE
	t.roles = Role::READ_AND_WRITE
end

Role.find_or_create_by(name: "Engineering Admin") do |t|
	t.xml_files = Role::READ
	t.parts = Role::READ_AND_WRITE
	t.boms = Role::READ_AND_WRITE
	t.documents = Role::READ_AND_WRITE
	t.document_uploads = Role::READ_AND_WRITE
end

Role.find_or_create_by(name: "User") do |t|
	t.settings = Role::READ
	t.xml_files = Role::READ
	t.parts = Role::READ
	t.boms = Role::READ
	t.documents = Role::READ
	t.document_uploads = Role::READ
	t.user_management = Role::READ
end

User.find_or_create_by(email: "admin@app.com") do |t|
	t.first_name = "Jungo"
	t.last_name = "Super Admin"
	t.password = 'password'
	t.password_confirmation = 'password'
	t.role = super_admin
end 
