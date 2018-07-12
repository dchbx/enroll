module IvlHelper
	def individual_market_is_enabled?
		Settings.aca.market_kinds.include?("individual")
	end
	def self.individual_market_is_enabled?
		Settings.aca.market_kinds.include?("individual")
	end
end
