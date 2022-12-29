class DocumentsService < BaseService
	attr_accessor :xml_file, :document
	def initialize(request, params, user)
		super(request, params, user)
		self.xml_file = get_xml_file
		self.document = get_document
	end

	def index
		documents = xml_file.documents.where.not(doc_type: ["DeletedDocumentLinks", "AddedDocumentLinks", "ChangedDocumentLinks", "UnchangedDocumentLinks"]).where(condition).page(params[:page]).per(params[:per_page]).order(status: :asc, created_at: :asc)
		[@xml_file, documents]
	end

	def show
		[@xml_file, @document]
	end

	def edit
		get_data
		[@xml_file, @document]
	end

	def update
		@document.update(document_params)
		[@xml_file, @document.reload]
	end

	def re_process
		if @document.deleted?
			Document.process_delete_document(@xml_file, @document, process_to_odoo=true)
		else
			Document.process_create_document(@xml_file, @document, process_to_odoo=true)
		end
		@document
	end

	def destroy
		@document.destroy
	end

	def get_data
		if @document.deleted?
			Document.process_delete_document(@xml_file, @document)
		else
			Document.process_create_document(@xml_file, @document)
		end
	end

	def req_body
		@setting = Setting.last
		get_data
		@body = {"access_token": @setting.access_token }
		if document.document_type != "Delete"
			@body["document_list"] = document.odoo_body["document_list"]
		else
			@body["delete_list"] = [{part_no: document.odoo_part_number}]
		end
		[document, {
					"params": @body
				}.to_json]
	end

	private

		def condition
			params[:type].present? ? { doc_type: params[:type] } : {}
		end

		def get_document
			Document.find_by(id: params[:id] || params[:document_id]) if params[:id] || params[:document_id]
		end

		def get_xml_file
			XmlFile.find_by(id: params[:xml_file_id])
		end

		def document_params
			params.require(:document).permit!
		end
end
