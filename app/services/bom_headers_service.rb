class BomHeadersService < BaseService
	attr_accessor :xml_file, :bom_header, :bom_components
	def initialize(request, params, user)
		super(request, params, user)
		self.xml_file = get_xml_file
		self.bom_header = get_bom_header
		self.bom_components = get_bom_components
	end

	def index
		bom_headers = xml_file.bom_headers.where(condition).page(params[:page]).per(params[:per_page]).order(status: :asc, created_at: :asc)
		[xml_file, bom_headers]
	end

	def show
		[@xml_file, @bom_header, @bom_components]
	end

	def edit
		[@xml_file, @bom_header, @bom_components]
	end

	def update
		@bom_header.update(bom_header_params)
		[@xml_file, @bom_header.reload]
	end

	def re_process
		BomHeader.process_bom(@bom_header)
		@bom_header
	end

	def destroy
		@bom_header.destroy
	end

	def req_body
		@setting = Setting.last
		@body = {"access_token": @setting.access_token }
		if bom_header.bom_type == "AddedBOMs"
			@body["part_values"] = [{
				part: bom_header.odoo_part_number,
				child_ids: bom_components.map { |e| {part: e.odoo_part_number, qty: e.quantity} }
			}]
		elsif bom_header.bom_type != "DeletedBOMs"
			@body["part_update_values"] = [{
				part: bom_header.odoo_part_number,
				child_ids: bom_components.map { |e| {part: e.odoo_part_number, qty: e.quantity} }
			}]
		else
			@body["bom_id"] = [bom_header.odoo_part_number]
			@body["del_child_ids"] = bom_components.pluck(:odoo_part_number).odoo_part_number
		end
		[bom_header, {
					"params": @body
				}.to_json]
	end

	private

		def condition
			params[:type].present? ? { bom_type: params[:type] } : {}
		end

		def get_bom_header
			BomHeader.find_by(id: params[:id] || params[:bom_header_id]) if params[:id] || params[:bom_header_id]
		end

		def bom_header_params
			params.require(:bom_header).permit(:odoo_part_number, bom_components_attributes: [:id, :odoo_part_number, :quantity, :_destroy])
		end

		def get_bom_components
			if @bom_header
				if @bom_header.bom_type == "AddedBOMs"
					@bom_components = @bom_header.bom_components.where(odoo_type: ["Add", nil])
				else
					@bom_components = @bom_header.bom_components.where("odoo_type is null or odoo_type != 'Add'")
				end
			else
				[]
			end
		end

		def get_xml_file
			XmlFile.find_by(id: params[:xml_file_id])
		end
end
