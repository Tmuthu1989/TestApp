class BaseService
  attr_accessor :current_user, :params, :request, :setting
  def initialize(request, params, user = nil)
    self.current_user = user
    self.params = params
    self.request = request
    self.setting = Setting.last || Setting.create(app_name: "Read XML")
  end

  def settings
    if request.post?
      setting.update(setting_params)
    end
    setting
  end

  def get_layout
    if current_user.present?
      'admin'
    else
      'application'
    end
  end

  private
    def setting_params
      params.require(:setting).permit(:app_name, :xml_files_path, {api_config: [:base_url, :auth, :product_creation, :product_update, :product_list, :product_delete, :auth_login, :auth_password, :auth_db, :bom_search, :bom_create, :bom_update, :bom_delete]} )
    end
end
