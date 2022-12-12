class ApplicationController < ActionController::Base
	before_action :authenticate_user!
	layout :get_layout
	before_action :configure_permitted_parameters, if: :devise_controller?
	include Pundit

	rescue_from Pundit::NotAuthorizedError do 
		redirect_to root_path, alert: "Unauthorized Access!"
	end

	def settings
		raise Pundit::NotAuthorizedError if request.get? && !policy(Setting).read_settings?
		raise Pundit::NotAuthorizedError if request.post? && !policy(Setting).write_settings?
		@setting = BaseService.new(request, params, current_user).settings
		if request.post?
			redirect_to settings_path, notice: "Settings updated successfully!"
		end
	end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :role_id])
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
