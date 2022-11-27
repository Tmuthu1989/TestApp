Setting.destroy_all
Setting.create(
	xml_files_path: "/home/tringapps/Desktop", 
	app_name: "Read XML",
	api_config: {
		"base_url" => "https://odoo-test.jungo.eu",
		"auth" => "/api/token",
		"product_list" => "/get/product_list",
		"product_creation" => "/api/product_create",
		"product_update" => "/api/product_update",
		"product_delete" => "/api/product_delete",
		"auth_login" => "admin",
		"auth_password" => "admin",
		"auth_db" => "odoo-test"
	}
)
User.find_or_create_by(email: "admin@app.com") do |t|
	t.password = 'password'
	t.password_confirmation = 'password'
end 
