module BenefitMarkets
	module Configurations
	  class Configuration
	    include Mongoid::Document
	    include Mongoid::Timestamps

	    embedded_in :benefit_market, inverse_of: 'configuration'
	  end
	end
end