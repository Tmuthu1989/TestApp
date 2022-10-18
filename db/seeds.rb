@setting = Setting.last
Setting.create(xml_files_path: "/home/tringapps/Desktop", app_name: "Read XML") if !@setting
User.find_or_create_by(email: "admin@app.com") do |t|
	t.password = 'password'
	t.password_confirmation = 'password'
end 
if Post.count == 0
	10.times do |n|
		Post.create(title: Faker::Lorem.sentence(word_count: 3), body: Faker::Lorem.paragraph(sentence_count: 4))
	end
end
	
