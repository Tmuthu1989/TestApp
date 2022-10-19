class ProcessXmlFilesJob < ApplicationJob
  queue_as :default

  def perform(xml_file_id)
    xml_file = XmlFile.find_by(id: xml_file_id)
    if xml_file
      xml_file.process_xml
    end
  end
end
