class XmlFile < ApplicationRecord
	has_many :parts, dependent: :destroy
	after_create :process_file

	def process_file
		ProcessXmlFilesJob.perform_later(self.id)
	end

	def process_xml
		xml_file = self
		json_content = Hash.from_xml(xml_file.file_content)
		if json_content
			seed_parts(json_content["COLLECTION"])
			Part.process_parts(self)
		end

		ActionCable.server.broadcast "process_xml_files:#{User.first.id}", {message: "<b>1/10</b> files are processed!"}
	end

	def seed_parts(json_content)
		transaction_obj = json_content["Release"]["Transaction"]
		["AddedParts", "ChangedParts", "UnchangedParts", "DeletedParts"].each do |part_type|
			if json_content[part_type].present? && json_content[part_type]["Part"].present?
				parts = json_content[part_type]["Part"]
				parts = [parts] if parts.class.to_s != "Array"
				parts.each do |part|
					self.parts.create(part_name: part["Name"], part_number: part["Number"], part_type: part_type, part_json: part, part_xml: part.to_xml(root: :Part), created_by: transaction_obj["CreatedBy"], transaction_obj: transaction_obj)
				end
			end
		end
	end
end
