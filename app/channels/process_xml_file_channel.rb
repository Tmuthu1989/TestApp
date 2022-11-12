class ProcessXmlFileChannel < ApplicationCable::Channel
  def subscribed
    stream_from "process_xml_files:#{current_user.id}" if current_user
  end

  def unsubscribed
    stop_all_streams
  end
end
