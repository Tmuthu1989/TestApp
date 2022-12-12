class DocumentUpload < ApplicationRecord
  belongs_to :xml_file
  belongs_to :document

  def pending?
    status != AppConstants::FILE_STATUS[:success]
  end
end
