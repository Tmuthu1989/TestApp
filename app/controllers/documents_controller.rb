class DocumentsController < ApplicationController
  before_action :init_service!

  def index
    @xml_file, @documents = @service.index
  end

  def show
    @xml_file, @document = @service.show
  end

  def edit
    @xml_file, @document = @service.edit
  end

  def update
    @xml_file, @document = @service.update
    redirect_to xml_file_documents_path(@document.xml_file_id)
  end

  def re_process
    @document = @service.re_process
    redirect_to xml_file_documents_path(@document.xml_file_id), alert: @document.error.present? ? "Something wrong in this Document." : nil, notice: @document.error.blank? ? "Document reprocessed successfully." : nil
  end

  def destroy
    @service.destroy
    redirect_to xml_file_documents_path(@document.xml_file_id), notice: "Document Deleted"
  end

  def req_body
    @document, @body = @service.req_body
  end

  private
    def init_service!
      authorize(Document)
      @service = DocumentsService.new(request, params, current_user)
    end
end
