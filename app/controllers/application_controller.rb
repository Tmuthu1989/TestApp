class ApplicationController < ActionController::Base
	before_action :authenticate_user!
	layout :get_layout

	def settings
		@setting = BaseService.new(request, params, current_user).settings
	end

	private
		def get_layout
			if current_user.present?
				'admin'
			else
				'application'
			end
		end
end
