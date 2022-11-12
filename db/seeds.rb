Setting.destroy_all
Setting.create(
	xml_files_path: "/home/tringapps/Desktop", 
	app_name: "Read XML",
	api_config: {
		"base_url" => "http://localhost:3000",
		"auth" => "/api/token",
		"product_list" => "/api/product_list",
		"product_creation" => "/api/product_create",
		"product_update" => "/api/product_update",
		"product_delete" => "/api/product_delete"
	}
)
User.find_or_create_by(email: "admin@app.com") do |t|
	t.password = 'password'
	t.password_confirmation = 'password'
end 
