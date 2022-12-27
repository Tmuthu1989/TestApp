class CommonUtils
	def self.broadcast_message(channel_prefix, channels, message)
		channels.each do |channel|
			ActionCable.server.broadcast "#{channel_prefix}#{channel}", {message: message}
		end
	end
end
