class XmlFile < ApplicationRecord
	has_many :parts, dependent: :destroy
	has_many :http_requests, dependent: :destroy
	has_many :bom_headers, dependent: :destroy
	has_many :bom_components, dependent: :destroy
	has_many :documents, dependent: :destroy
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
		begin
			
			xml_file = XmlFile.find_by(id: id)
			Part.load_parts(xml_file)
			BomHeader.load_bom_headers(xml_file)
			BomComponent.load_bom_components(xml_file)
			Document.load_documents(xml_file)
	    Part.process_parts(xml_file)
	    BomHeader.process_boms(xml_file)
	    Document.process_documents(xml_file)
	    parts = xml_file.parts
	    success_parts_count = parts.success.count
	    bom_components = xml_file.bom_components
	    success_bom_component_count = bom_components.success.count
	    documents = xml_file.documents
	    success_documents_count = documents.success.count
			xml_file.update(status: AppConstants::FILE_STATUS[:success]) if parts.count === success_parts_count && bom_components.count === success_bom_component_count  && documents.count === success_documents_count
			@success_count += 1
			ActionCable.server.broadcast "process_xml_files:#{User.first.id}", {message: "<b>#{@success_count}/#{@total_count}</b> files are processed!"}
		rescue StandardError => e
			error = {
        error_type: "StandardError",
        title: e,
        message: e.message,
        backtrace: e.backtrace
      }
      HttpRequest.create(error: error, xml_file_id: id)
		end
	end

	def self.process_pending_xmls
		xml_files = XmlFile.pending.pluck(:id)
		@total_count = xml_files.count
		@success_count = 0
		ActionCable.server.broadcast "process_xml_files:#{User.first.id}", {message: "Started processing for #{xml_files.count} files!"}
		xml_files.each do |id|
			process_file(id)
		end		
	end

end
