class Hash
	def to_obj
		JSON.parse to_json, object_class: OpenStruct
	end
end