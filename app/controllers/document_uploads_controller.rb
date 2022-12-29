class DocumentUploadsController < ApplicationController
  before_action :init_service!

  def index
    @xml_file, @document_uploads = @service.index
  end

  def show
    @xml_file, @document_upload = @service.show
  end

  def edit
    @xml_file, @document_upload = @service.show
  end

  def update
    @xml_file, @document_upload = @service.update
    redirect_to xml_file_document_uploads_path(@document_upload.xml_file_id)
  end

  def re_process
    @document_upload = @service.re_process
    redirect_to xml_file_document_uploads_path(@document_upload.xml_file_id), alert: @document_upload.error.present? ? "Something wrong in this Document Upload." : nil, notice: @document_upload.error.blank? ? "Document Uploaded successfully." : nil
  end

  def destroy
    @service.destroy
    redirect_to xml_file_document_uploads_path(@document_upload.xml_file_id), notice: "BOM Deleted"
  end

  def req_body
    @document_upload, @body = @service.req_body
  end

  private
    def init_service!
      authorize(DocumentUpload)
      @service = DocumentUploadsService.new(request, params, current_user)
    end
end
