module ApplicationHelper
	def title(page_title)
	  content_for :title, page_title.to_s
	end

	def page_name(page_name)
	  content_for :page_name, page_name.to_s
	end

	def check_active(path, is_root=false)
		(request.path === path || request.path.include?("/#{path}") || request.path.include?("#{path}/")) || (is_root && request.path === "/") ? 'active' : ''
	end
end
