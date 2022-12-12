class UserMailer < ApplicationMailer
	def send_password_mail(user)
		@user = user
		mail(to: user.email, subject: "Login Details")
	end
end
