module ApplicationHelper
	def title(page_title)
	  content_for :title, page_title.to_s
	end

	def page_name(page_name)
	  content_for :page_name, page_name.to_s
	end

	def check_active(path, is_root=false)
		'active' if (request.path === path || request.path.include?("/#{path}") || request.path.include?("#{path}/")) || (is_root && request.path === "/")
	end

	def is_active?(path)
		"active" if request.path === path
	end

	def current_page
		params[:page].to_i > 0 ? params[:page].to_i - 1 : 0
	end
end
