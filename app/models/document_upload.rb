class DocumentUpload < ApplicationRecord
  belongs_to :xml_file
  belongs_to :document
  scope :success, -> {where(status: AppConstants::FILE_STATUS[:success])}
  def pending?
    status != AppConstants::FILE_STATUS[:success]
  end
end
