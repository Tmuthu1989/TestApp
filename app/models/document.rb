class Document < ApplicationRecord
  belongs_to :xml_file
  has_many :document_uploads, dependent: :destroy


  scope :pending, -> {where.not(status: AppConstants::FILE_STATUS[:success])}
  scope :success, -> {where(status: AppConstants::FILE_STATUS[:success])}
  scope :added, -> {where(doc_type: "AddedDocuments")}
  scope :changed, -> {where(doc_type: "ChangedDocuments")}
  scope :unchanged, -> {where(doc_type: "UnchangedDocuments")}
  scope :deleted, -> {where(doc_type: ["DeletedDocuments", "DeletedDocumentLinks"])}

  def self.deleted?
    ["DeletedDocuments", "DeletedDocumentLinks"].include?(doc_type)
  end

  def pending?
    status != AppConstants::FILE_STATUS[:success]
  end

  def self.load_documents(xml_file)
    json_obj = xml_file.json_obj
    if json_obj
      json_content = json_obj["COLLECTION"]
      ["AddedDocuments", "ChangedDocuments", "UnchangedDocuments", "DeletedDocuments", "DeletedDocumentLinks"].each do |type|
        if json_content[type].present? && (json_content[type]["Document"].present? || json_content[type]["DocumentLink"].present?)
          documents = json_content[type]["Document"] || json_content[type]["DocumentLink"]
          if documents.present?
            documents = [documents] if documents.class.to_s != "Array"
            documents.each do |document|
              xml_file.documents.create(number: document["Number"] || document["AssociatedObjectNumber"], document_number: document["DocumentNumber"], name: document["Name"] || document["AssociatedObjectNumber"], doc_type: type, json_obj: document, xml_content: document.to_xml(root: :Document))
            end
          end
        end
      end
    end
  end

  def self.init_config(xml_file, document=nil)
    @parts ||= xml_file.parts.pluck(:part_name, :odoo_part_number).to_h
    @parts_number ||= xml_file.parts.pluck(:part_number, :odoo_part_number).to_h
    @setting ||= Setting.last
    @odoo_service ||= OdooService.new(@setting, xml_file.id)
    @document_names ||= document ? [document.name] : xml_file.documents.pluck(:name).compact
    @parts_search ||= @document_names.present? ? @odoo_service.get_products(@document_names).map { |part| [part.part, part.default_code] }.to_h : {}
    @existing_documents ||= @odoo_service.search_documents.map { |doc| [doc.document_number, doc.document_url] }.to_h
  end

  def self.process_documents(xml_file)
    begin
      init_config(xml_file)
      process_create_documents(xml_file)
      process_delete_documents(xml_file)
    rescue StandardError => e
      error = {
        error_type: "StandardError",
        title: e,
        message: e.message,
        backtrace: e.backtrace
      }
      HttpRequest.create(error: error, xml_file_id: xml_file.id)
    end
  end

  def self.process_create_document(xml_file, document, process_to_odoo=false)
    init_config(xml_file, (process_to_odoo ? document : nil))
    @document_ids ||= []
    @odoo_documents ||= []
    document = get_document_type(document)
    document = generate_part_number(document)
    document, document_url, new_file_name, old_file_name = generate_url(document, document.number)
    if document.odoo_part_number.present? && document.document_url.present? && document.document_number.present? && document.document_type.present?
      odoo_document = {
        part_no: document.odoo_part_number,
        document_number: document.document_number,
        document_url: document.document_url,
        type: document.document_type
      }
      odoo_docs = []
      @document_ids << document.id
      unless @existing_documents[document.document_number].present? && @existing_documents[document.document_number] === odoo_document[:document_url]
        @odoo_documents << odoo_document 
        odoo_docs << odoo_document
      end
      if @setting.documents_folder.present? && document.odoo_part_number.present?
        docs = Dir.glob("#{@setting.documents_folder}/#{document.part_number}*.*")
        docs += Dir.glob("#{@setting.documents_folder}/#{document.odoo_part_number}*.*")
        docs.each do |doc|
          ext = File.extname(doc)
          if ext === ".dxf"
            odoo_document[:type] = "2d"
            odoo_document[:document_url] = odoo_document[:document_url].ext(".dxf")
            unless @existing_documents[document.document_number].present? && @existing_documents[document.document_number] === odoo_document[:document_url]
              @odoo_documents << odoo_document 
              odoo_docs << odoo_document
            end
          end
          new_file_name = doc.include?(document.odoo_part_number) ? doc : doc.gsub(document.part_number, document.odoo_part_number)
          new_file_name = File.rename(doc, new_file_name) unless doc.include?(document.odoo_part_number)
          ProcessDocumentUploadJob.perform_later(document.id, new_file_name)
        end
      end
      document.odoo_body = { document_list: odoo_docs } if odoo_docs
      document.save
    end
    if process_to_odoo && @odoo_documents.present?
      result = @odoo_service.create_documents(@odoo_documents)
      document.update(status: AppConstants::FILE_STATUS[:success], odoo_type: "Add") if result.present? && @document_ids.present?
    end
    @odoo_documents
  end

  def self.process_create_documents(xml_file)
    @document_ids = []
    @odoo_documents = []
    xml_file.documents.pending.where.not(doc_type: ["DeletedDocuments", "DeletedDocumentLinks"]).each do |document|
      process_create_document(xml_file, document)
    end
    if @odoo_documents.present?
      result = @odoo_service.create_documents(@odoo_documents)
      xml_file.documents.where(id: @document_ids).update_all(status: AppConstants::FILE_STATUS[:success], odoo_type: "Add") if result.present? && @document_ids.present?
    end
  end

  def self.process_delete_document(xml_file, document, process_to_odoo=false)
    init_config(xml_file, (process_to_odoo ? document : nil))
    @document_ids ||= []
    @odoo_documents ||= []
    document = generate_part_number(document, true)
    @odoo_documents << document.odoo_part_number if document.odoo_part_number.present?
    @document_ids << document.id if document.odoo_part_number.present?
    document.save
    if process_to_odoo && odoo_documents.present?
      result = @odoo_service.delete_documents(@odoo_documents)
      document.update(status: AppConstants::FILE_STATUS[:success], odoo_type: "Delete") if result.present?
    end
  end

  def self.process_delete_documents(xml_file)
    document_ids = []
    odoo_documents = []
    xml_file.documents.pending.deleted.each do |document|
      process_delete_document(xml_file, document)
    end
    if odoo_documents.present?
      result = @odoo_service.delete_documents(odoo_documents)
      xml_file.documents.where(id: document_ids).update_all(status: AppConstants::FILE_STATUS[:success], odoo_type: "Delete") if result.present? && document_ids.present?
    end
  end

  def self.get_part_number(name, by_number=false)
    (by_number ? @parts_number[name] : @parts[name]) || @parts_search[name]
  end

  def self.generate_part_number(document, by_number=false)
    new_part_number = part_number = nil
    if document.name.present?
      if document.name.to_s.include?("_")
        name = document.name.split("_")[0]
        part_number = get_part_number(name, by_number)
        new_part_number = part_number ? "#{part_number}_#{document.name.split("_")[1]}" : nil
      else
        part_number = new_part_number = get_part_number(document.name, by_number)
      end
    end
    document.part_number = document.name.to_s.split("_")[0]
    document.odoo_part_number = part_number
    document.document_number = new_part_number
    document
  end

  def self.generate_url(document, old_file_name)
    url = nil
    if document.odoo_part_number.present? && old_file_name.present?
      ext = File.extname(old_file_name)
      old_file_name_without_ext = File.basename(old_file_name, ext)
      new_file_name_without_ext = @setting.rename_document ? document.odoo_part_number : old_file_name_without_ext
      new_file_name = "#{new_file_name_without_ext}#{ext}"
      if [".ASM", ".PRT"].include?(ext)
        url = "#{@setting.api_config["obs_url"]}#{new_file_name_without_ext}.stp"
        new_extention = ".stp"
      else
        new_extention = ".pdf"
        url = "#{@setting.api_config["obs_url"]}#{new_file_name_without_ext}.pdf"
      end
    end
    document.document_url ||= url
    document.new_file_name ||= new_file_name_without_ext
    document.original_file_name ||= old_file_name_without_ext
    document.extention ||= ext
    document.new_extention ||= new_extention
    [document, url, new_file_name, old_file_name]
  end

  def self.get_document_type(document)
    document_type = nil
    if document.number.present?
      file_type = File.extname(document.number)
      if file_type.present?
        if [".ASM", ".PRT"].include?(file_type)
          document_type = "3d"  
        else
          document_type = "2d"
        end
      else
        document_type = "specification"
      end
    end
    document.document_type = document_type
    document
  end

  def self.upload_document(document_id, file, is_odoo_upload=false)
    document = Document.find_by(id: document_id)
    if document
      doc_error = document.error
      doc_error["document_uploads"] ||= {}
      error = {}
      status = document.status
      file_name = File.basename(file)
      document_upload = document.document_uploads.find_or_create_by(xml_file_id: document.xml_file_id, file_name: file_name, is_odoo_upload: is_odoo_upload, file_path: file)
      begin
        @setting ||= Setting.last
        @odoo_service ||= OdooService.new(@setting, document.xml_file_id)
        params = {
          key: file_name,
          file: File.open(document_upload.file_path)
        }
        response, error = is_odoo_upload ? @odoo_service.odoo_upload(params) : @odoo_service.obs_upload(params)
        doc_error["document_uploads"][file_name] = "#{file_name} upload failed due to #{error[:message]} from server" if error.present?
      rescue StandardError => e
        error = {
          error_type: "StandardError",
          title: e,
          message: e.message,
          backtrace: e.backtrace
        }
        
        doc_error["document_uploads"][file_name] = "#{file_name} upload failed due to #{e.message}"
        HttpRequest.create(error: error, xml_file_id: document.xml_file_id)
        status = AppConstants::FILE_STATUS[:failed]
      end
      document.update(error: doc_error)
      document_upload.update(file_name: file_name, document_number: document.document_number, number: document.number, part_number: document.name, odoo_part_number: document.odoo_part_number, status: status, error: error, xml_file_id: document.xml_file_id)

    end
  end
end
