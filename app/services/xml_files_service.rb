class XmlFilesService < BaseService
	attr_accessor :xml_file
	def initialize(request, params, user)
		super(request, params, user)
		self.xml_file = get_xml_file
	end

	def read_xml_files
		if setting.xml_files_path
			existing_files = XmlFile.pluck(:file_name)
			new_files = Dir.glob("#{setting.xml_files_path}/*.xml").select { |file|
				file_name = File.basename(file)
				!existing_files.include?(file_name)
			}
			i = 0
			new_files.each do |file_path|
				file_name = File.basename(file_path)
				unless existing_files.include?(file_name)
					# CommonUtils.broadcast_message("process_xml_files:", User.pluck(:id), "<b>#{@success_count}/#{@total_count}</b> files are processed!")
					begin
						file_content = File.read(file_path)
						XmlFile.create(file_name: file_name, file_path: file_path, file_content: file_content, date: Date.today.strftime("%d-%m-%Y"), status: AppConstants::FILE_STATUS[:pending])
					rescue Exception => e
						XmlFile.create(file_name: file_name, file_path: file_path, file_error: e.message, date: Date.today.strftime("%d-%m-%Y"), status: AppConstants::FILE_STATUS[:failed])
					end
				end
			end
			ProcessXmlFilesJob.set(wait: 2.seconds).perform_later
		end
	end

	def index
		XmlFile.order(created_at: :desc)
	end

	def show
		xml_file
	end

	def destroy
		xml_file.destroy
	end

	def get_xml_file
		XmlFile.find_by(id: params[:id] || params[:xml_file_id])
	end
end
