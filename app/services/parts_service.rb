class PartsService < BaseService
	attr_accessor :xml_file, :part
	def initialize(request, params, user)
		super(request, params, user)
		self.xml_file = get_xml_file
		self.part = get_part
	end

	def index
		parts = xml_file.parts.where(condition).page(params[:page]).per(params[:per_page]).order(status: :asc, created_at: :asc)
		[xml_file, parts]
	end

	def show
		[@xml_file, @part]
	end

	def edit
		[@xml_file, @part]
	end

	def update
		@part.update(part_params)
		[@xml_file, @part.reload]
	end

	def re_process
		@part.process_part
		@part
	end

	def destroy
		@part.destroy
	end

	def req_body
		@setting = Setting.last
		@body = {"access_token": @setting.access_token }
		if part.odoo_type != "Delete"
			@body["pp"] = [part.odoo_body]
		else
			@body["part_no"] = [part.odoo_part_number]
		end
		[part, {
					"params": @body
				}.to_json]
	end

	private

		def condition
			params[:type].present? ? { part_type: params[:type] } : {}
		end

		def get_part
			Part.find_by(id: params[:id] || params[:part_id]) if params[:id] || params[:part_id]
		end

		def part_params
			params.require(:part).permit!
		end


		def get_xml_file
			XmlFile.find_by(id: params[:xml_file_id])
		end
end
