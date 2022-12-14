class XmlFile < ApplicationRecord
	has_many :parts, dependent: :destroy
	has_many :http_requests, dependent: :destroy
	has_many :bom_headers, dependent: :destroy
	has_many :bom_components, dependent: :destroy
	has_many :documents, dependent: :destroy
	has_many :document_uploads, dependent: :destroy
	after_create :update_json_content

	scope :pending, -> {where.not(status: AppConstants::FILE_STATUS[:success])}
	scope :success, -> {where(status: AppConstants::FILE_STATUS[:success])}

	def update_json_content
		json_content = Hash.from_xml(self.file_content)
		self.update(json_obj: json_content)
	end

	def self.process_file(id)
		ProcessXmlFilesJob.perform_later(id)
	end

	def self.process_xml(id)
		xml_file = XmlFile.find_by(id: id)
		begin
			
			Part.load_parts(xml_file)
			BomHeader.load_bom_headers(xml_file)
			BomComponent.load_bom_components(xml_file)
			Document.load_documents(xml_file)
	    Part.process_parts(xml_file)
	    BomHeader.process_boms(xml_file)
	    Document.process_documents(xml_file)
	    parts = xml_file.parts
	    bom_headers = xml_file.bom_headers
	    success_parts_count = parts.success.count
	    bom_components = xml_file.bom_components
	    documents = xml_file.documents
	    success_documents_count = documents.success.count
	    document_uploads = xml_file.document_uploads
	    success_document_uploads_count = document_uploads.success.count
			if parts.count === success_parts_count && documents.count === success_documents_count && bom_headers.count === bom_headers.success.count && document_uploads.count === success_document_uploads_count
				xml_file.update(status: AppConstants::FILE_STATUS[:success]) 
			else
				xml_file.update(status: AppConstants::FILE_STATUS[:failed], file_error: "This file having some problem") 
			end
			@success_count += 1
			CommonUtils.broadcast_message("process_xml_files:", User.pluck(:id), "<b>#{@success_count}/#{@total_count}</b> files are processed!")
		rescue StandardError => e
			error = {
        error_type: "StandardError",
        title: e,
        message: e.message,
        backtrace: e.backtrace
      }
      xml_file.update(file_error: e.message, status: AppConstants::FILE_STATUS[:failed])
      HttpRequest.create(error: error, xml_file_id: id)
		end
	end

	def self.process_pending_xmls
		xml_files = XmlFile.pending.pluck(:id)
		@total_count = xml_files.count
		@success_count = 0
		users = User.all
		CommonUtils.broadcast_message("process_xml_files:", users.pluck(:id), "Started processing for #{xml_files.count} files!")
		xml_files.each_with_index do |id, i|
			# process_file(id)
			CommonUtils.broadcast_message("process_xml_files:", users.pluck(:id), "<b>#{i+1}/#{xml_files.count}</b> files processing!")
			process_xml(id)
		end		
	end

end
