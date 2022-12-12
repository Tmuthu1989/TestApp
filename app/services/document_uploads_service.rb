class DocumentUploadsService < BaseService
	attr_accessor :xml_file, :document_upload
	def initialize(request, params, user)
		super(request, params, user)
		self.xml_file = get_xml_file
		self.document_upload = get_document_upload
	end

	def index
		document_uploads = xml_file.document_uploads.includes(:document).where(condition).page(params[:page]).per(params[:per_page]).order(status: :asc, created_at: :asc)
		[@xml_file, document_uploads]
	end

	def show
		[@xml_file, @document_upload]
	end

	def edit
		[@xml_file, @document_upload]
	end

	def update
		@document_upload.update(document_upload_params)
		[@xml_file, @document_upload.reload]
	end

	def re_process
		Document.upload_document(@document_upload.document_id, @document_upload.file_path, @document_upload.is_odoo_upload)
		@document_upload
	end

	def destroy
		@document_upload.destroy
	end

	private

		def condition
			params[:type].present? ? { is_odoo_upload: params[:type].to_s.true? } : {}
		end

		def get_document_upload
			DocumentUpload.find_by(id: params[:id] || params[:document_upload_id]) if params[:id] || params[:document_upload_id]
		end

		def get_xml_file
			XmlFile.find_by(id: params[:xml_file_id])
		end
end
