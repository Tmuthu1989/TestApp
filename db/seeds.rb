# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
User.find_or_create_by(email: "admin@app.com") do |t|
	t.password = 'password'
	t.password_confirmation = 'password'
end 

10.times do |n|
	Post.create(title: Faker::Lorem.sentence(word_count: 3), body: Faker::Lorem.paragraph(sentence_count: 4))
end