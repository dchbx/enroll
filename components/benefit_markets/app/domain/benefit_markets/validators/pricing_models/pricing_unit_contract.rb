# frozen_string_literal: true

module BenefitMarkets
  module Validators
  	module PricingModels
	    class PricingUnitContract < Dry::Validation::Contract

	      params do
	        required(:name).filled(:string)
	        required(:display_name).filled(:string)
	        required(:order).filled(:integer)
	      end
	    end
	  end
  end
end