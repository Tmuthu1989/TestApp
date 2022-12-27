class OdooService
	attr_accessor :base_url, :api_config, :setting, :xml_file_id, :request_type
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
		HttpRequest.create(req_body: body, request_type: "Auth", res_body: res_body, error: error, xml_file_id: xml_file_id, req_url: api_url)
		setting.access_token
	end

	def get_products(products)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"part" => products
		}
		body = {
			"params" => params
		}
		result = []
		res_body = {}
		error = {}
		@request_type = "Search Part"
		api_url = "#{base_url}#{}"
		response = odoo_request(api_config.product_list, body, setting.cookie)[0]
		result = response ? response.result.product_list : []
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
		@request_type = from_update ? "Update Parts" : "Create Parts"
		url = from_update ? api_config.product_update : api_config.product_creation
		odoo_request(url, body, setting.cookie)
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
		@request_type = "Delete Parts"
		odoo_request(api_config.product_delete, body, setting.cookie)
	end

	def search_boms(components=[])
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"Bom_part" => components
		}
		body = {
			"params" => params
		}
		result = []
		error = {}
		@request_type = "Search BOMs"
		response = odoo_request(api_config.bom_search, body, setting.cookie)[0]
		if response.body
			result = response.result.search_values
		end
		result
	end

	def create_boms(components)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"part_values" => components
		}
		body = {
			"params" => params
		}
		result = nil
		error = {}
		@request_type = "Create BOMs"
		odoo_request(api_config.bom_create, body, setting.cookie)
	end

	def update_boms(components)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"part_update_values" => components
		}
		body = {
			"params" => params
		}
		result = nil
		error = {}
		@request_type = "Update BOMs"
		odoo_request(api_config.bom_update, body, setting.cookie)
	end

	def delete_bom_components(bom_ids, components)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"bom_id" => bom_ids,
			"del_child_ids" => components
		}
		body = {
			"params" => params
		}
		result = []
		error = {}
		@request_type = "Delete BOM components"
		odoo_request(api_config.bom_component_delete, body, setting.cookie)
	end

	def delete_boms(components)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"part_delete_ids" => {
				"part" => components
			}
		}
		body = {
			"params" => params
		}
		result = nil
		error = {}
		@request_type = "Delete BOMs"
		odoo_request(api_config.bom_delete, body, setting.cookie)
	end

	def search_documents
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"search_list" => [{part_no: []}]
		}
		body = {
			"params" => params
		}
		result = []
		error = {}
		@request_type = "Search Documents"
		response = odoo_request(api_config.document_search, body, setting.cookie)[0]
		if response.body
			result = response.result.document_list
		end
		result
	end

	def create_documents(documents)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"document_list" => documents
		}
		body = {
			"params" => params
		}
		result = nil
		error = {}
		@request_type = "Create Documents"
		odoo_request(api_config.document_create, body, setting.cookie)
	end

	def delete_documents(documents)
		retries = 0
		access_token = setting.access_token || get_access_token
		params = {
			"access_token" => access_token,
			"delete_list" => [{part_no: documents}]
		}
		body = {
			"params" => params
		}
		result = nil
		error = {}
		@request_type = "Delete Documents"
		odoo_request(api_config.document_delete, body, setting.cookie)[0]
	end
	
	def odoo_error(error)
		{
			error_type: error.message,
			title: error.message,
			message: error.message,
			backtrace: error.data
		}
	end

	def odoo_request(url, body, cookie=nil)
		response = nil
		retries = 0
		res_body = {}
		error = {}
		begin
			api_url = "#{base_url}#{url}"
			resp = HttpService.new(api_url).post(body, cookie)
			res_body = resp.body.present? ? JSON.parse(resp.body) : {}
			response = resp.to_obj
			if (response.result.present? && response.result.status == "error" && response.result.message.include?("Access Token"))
				retries += 1
				get_access_token
				raise
			elsif response.error.present? || (response.result && response.result.status == "error")
				error = odoo_error(response.error || response.result)
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
		HttpRequest.create(req_body: body, request_type: @request_type, res_body: res_body, error: error, xml_file_id: xml_file_id, req_url: api_url)	
		[response, error[:message]]
	end

	def obs_upload(params)
    response = HttpService.new(api_config.obs_url).post_multi_part(params)
    error = {}
    result = nil

    if response["Error"].present?
      error = {
        error_type: "OBS Bucket Error",
        title: response["Error"]["Code"],
        message: response["Error"]["Message"],
        bucket_name: response["Error"]["BucketName"]
      }
    else
    	result = response
    end
    HttpRequest.create(req_body: params, request_type: "OBS File Upload", res_body: response, error: error, xml_file_id: xml_file_id, req_url: api_config.obs_url)	
    [result, error]
  end

  def odoo_upload(params)
  	api_url = "#{base_url}#{api_config.document_upload}"
    error = {}
    result = false
    retries = 0
    if api_config.document_upload.present?
    	begin
	    	response = HttpService.new(api_url).post_multi_part(params)
		    result = response
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
	    HttpRequest.create(req_body: params, request_type: "Odoo File Upload", res_body: response, error: error, xml_file_id: xml_file_id, req_url: api_url)	
	  end
    [result, error]
  end
	
end