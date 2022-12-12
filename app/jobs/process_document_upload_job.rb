class ProcessDocumentUploadJob < ApplicationJob
  queue_as :default

  def perform(document_id, file)
    Document.upload_document(document_id, file)
    ext = File.extname(file)
    Document.upload_document(document_id, file, true) if [".jpg", ".jpeg"].include?(ext.downcase)
  end
end
