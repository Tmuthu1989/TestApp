class OdooService
	attr_accessor :base_url, :api_config, :setting, :xml_file_id
	def initialize(setting=nil, xml_file_id=nil)
		self.setting = setting || Setting.last 
		self.api_config = self.setting.api_config.to_obj
		self.base_url = self.api_config.base_url
		self.xml_file_id = xml_file_id
	end

	def get_access_token
		access_token = nil
		body = {
	   "params" => {
        "login" => api_config.auth_login,
        "password" => api_config.auth_password,
        "db" => api_config.auth_db
	    }
		}
		error = {}
		res_body = {}
		begin
			api_url = "#{base_url}#{api_config.auth}"
			response = HttpService.new(api_url).post(body)
			cookie = response.headers["set-cookie"].to_s.split(";")[0]
			res_body = response
			response = response.to_obj
			access_token = response.result.request_value[0].access_token if response.result.present? && response.result.request_value.present? && response.result.request_value[0].present? && response.result.request_value[0].access_token.present?
			setting.update(access_token: access_token, cookie: cookie)
		rescue StandardError => e
			Rails.logger.error e
			error = {
				error_type: "StandardError",
				title: e,
				message: e.message,
				backtrace: e.backtrace
			}
		end
		HttpRequest.create(req_body: body, res_body: res_body, error: error, xml_file_id: xml_file_id, req_url: api_url)
		setting.access_token
	end

	def get_products(body={})
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token
		}
		params.merge!(body)
		body = {
			"params" => params
		}
		result = nil
		res_body = {}
		error = {}
		begin
			api_url = "#{base_url}#{api_config.product_list}"
			response = HttpService.new(api_url).post(body, setting.cookie)
			res_body = response
			response = response.to_obj
			if response.error.present?
				error = odoo_error(response)
			elsif response.result.present? && response.result.status == "error" && response.result.message.include?("Access Token")
				retries += 1
				get_access_token
				raise
			else
				result = response.result.product_list
			end
		rescue StandardError => e
			Rails.logger.error e
			if retries == 1
				retry
			else
				error = {
					error_type: "StandardError",
					title: e,
					message: e.message,
					backtrace: e.backtrace
				}
			end
		end
		HttpRequest.create(req_body: body, res_body: res_body, error: error, xml_file_id: xml_file_id, req_url: api_url)
		result
	end

	def create_products(products, from_update=false)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"pp" => products
		}
		body = {
			"params" => params
		}
		result = nil
		error = {}
		res_body = {}
		begin
			url = from_update ? api_config.product_update : api_config.product_creation
			api_url = "#{base_url}#{url}"
			response = HttpService.new(api_url).post(body, setting.cookie)
			res_body = response
			response = response.to_obj
			if response.error.present?
				error = odoo_error(response)
			elsif response.result.present? && response.result.status == "error" && response.result.message.include?("Access Token")
				retries += 1
				get_access_token
				raise
			else
				result = response
			end
		rescue StandardError => e
			Rails.logger.error e
			if retries == 1
				retry
			else
				error = {
					error_type: "StandardError",
					title: e,
					message: e.message,
					backtrace: e.backtrace
				}
			end
		end
		HttpRequest.create(req_body: body, res_body: res_body, error: error, xml_file_id: xml_file_id, req_url: api_url)	
		result
	end

	def update_products(products)
		create_products(products)
	end

	def delete_products(products)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"part_no" => products
		}
		body = {
			"params" => params
		}
		result = nil
		error = {}
		res_body = {}
		begin
			api_url = "#{base_url}#{api_config.product_delete}"
			response = HttpService.new(api_url).post(body, setting.cookie)
			res_body = response
			response = response.to_obj
			if response.error.present?
				error = odoo_error(response)
			elsif response.result.present? && response.result.status == "error" && response.result.message.include?("Access Token")
				retries += 1
				get_access_token
				raise
			else
				result = response
			end
		rescue StandardError => e
			Rails.logger.error e
			if retries == 1
				retry
			else
				error = {
					error_type: "StandardError",
					title: e,
					message: e.message,
					backtrace: e.backtrace
				}
			end
		end
		HttpRequest.create(req_body: body, res_body: res_body, error: error, xml_file_id: xml_file_id, req_url: api_url)	
		result
	end
	
	def odoo_error(response)
		{
			error_type: response.error.message,
			title: response.error.message,
			message: response.error.message,
			backtrace: response.error.data
		}
	end
	
end