class ProcessXmlFilesJob < ApplicationJob
  queue_as :default

  def perform(xml_file_id=nil)
    if xml_file_id
      XmlFile.process_xml(xml_file_id)
    else
      XmlFile.process_pending_xmls
    end
  end
end
