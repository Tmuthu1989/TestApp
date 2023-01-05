class XmlFilesController < ApplicationController
  before_action :init_service!

  def index
    @xml_files = @service.index
  end

  def show
    @xml_file = @service.show
  end

  def read_xml_files
    @xml_files = @service.read_xml_files
    redirect_to xml_files_path
  end

  def destroy
    @service.destroy
    redirect_to xml_files_path, notice: "File deleted"
  end

  private
    def init_service!
      authorize(XmlFile)
      @service = XmlFilesService.new(request, params, current_user)
    end
end
