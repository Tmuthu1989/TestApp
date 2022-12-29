class BomHeadersController < ApplicationController
  before_action :init_service!

  def index
    @xml_file, @bom_headers = @service.index
  end

  def show
    @xml_file, @bom_header, @bom_components = @service.show
  end

  def edit
    @xml_file, @bom_header, @bom_components = @service.show
  end

  def update
    @xml_file, @bom_header = @service.update
    redirect_to xml_file_bom_headers_path(@bom_header.xml_file_id)
  end

  def re_process
    @bom_header = @service.re_process
    redirect_to xml_file_bom_headers_path(@bom_header.xml_file_id), alert: @bom_header.error.present? ? "Something wrong in this BOM." : nil, notice: @bom_header.error.blank? ? "BOM reprocessed successfully." : nil
  end

  def destroy
    @service.destroy
    redirect_to xml_file_bom_headers_path(@bom_header.xml_file_id), notice: "BOM Deleted"
  end

  def req_body
    @bom_header, @body = @service.req_body
  end

  private
    def init_service!
      authorize(BomHeader)
      @service = BomHeadersService.new(request, params, current_user)
    end
end
