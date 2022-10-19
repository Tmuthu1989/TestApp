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
			process_parts(json_content["COLLECTION"])
		end

		ActionCable.server.broadcast "process_xml_files:#{User.first.id}", {message: "<b>1/10</b> files are processed!"}
	end

	def process_parts(json_content)
		["AddedParts", "ChangedParts", "UnchangedParts", "DeletedParts"].each do |part_type|
			if json_content[part_type] && json_content[part_type]["Part"] && json_content[part_type]["Part"].size > 0
				json_content[part_type]["Part"].each do |part|
					self.parts.create(part_name: part["Name"], part_number: part["Number"], part_type: part_type, part_json: part, part_xml: part.to_xml(root: :Part))
				end
			end
		end
	end
end
