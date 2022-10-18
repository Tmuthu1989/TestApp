module ApplicationHelper
	def title(page_title)
	  content_for :title, page_title.to_s
	end

	def page_name(page_name)
	  content_for :page_name, page_name.to_s
	end

	def check_active(path)
		request.path === path ? 'active' : ''
	end
end
