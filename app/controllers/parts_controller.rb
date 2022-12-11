class PartsController < ApplicationController
  before_action :init_service!

  def index
    @xml_file, @parts = @service.index
  end

  def show
    @xml_file, @part = @service.show
  end

  def edit
    @xml_file, @part = @service.show
  end

  def update
    @xml_file, @part = @service.update
    redirect_to xml_file_parts_path(@part.xml_file_id)
  end

  def re_process
    @part = @service.re_process
    redirect_to xml_file_parts_path(@part.xml_file_id), alert: @part.error.present? ? "Something wrong in this part." : nil, notice: @part.error.blank? ? "Part reprocessed successfully." : nil
  end

  def destroy
    @service.destroy
    redirect_to xml_file_parts_path(@part.xml_file_id), notice: "Part Deleted"
  end

  def req_body
    @part, @body = @service.req_body
  end

  private
    def init_service!
      @service = PartsService.new(request, params, current_user)
    end
end
