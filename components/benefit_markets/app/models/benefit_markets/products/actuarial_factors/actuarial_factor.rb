module BenefitMarkets
	module Products
		module ActuarialFactors
			class ActuarialFactor
				include Mongoid::Document
        include Mongoid::Timestamps
        
				field :active_year, type: Integer
				field :default_factor_value, type: Float
				field :issuer_profile_id, type: BSON::ObjectId

				field :max_integer_factor_key, type: Integer

				embeds_many :actuarial_factor_entries, class_name: "::BenefitMarkets::Products::ActuarialFactors::ActuarialFactorEntry"

				validates_presence_of :issuer_profile_id, :allow_blank => false
				validates_numericality_of :default_factor_value, :allow_blank => false
				validates_numericality_of :active_year, :allow_blank => false

				def lookup(key)
					entry = actuarial_factor_entries.detect { |rfe| rfe.factor_key == key }
					entry.nil? ? default_factor_value : entry.factor_value
				end

        def cacherize!
          @cached_values = {}
          actuarial_factor_entries.each do |entry|
            @cached_values[entry.factor_key] = entry.factor_value
          end
          self 
        end

        def cached_lookup(key)
          entry = @cached_values[key]
          entry.nil? ? default_factor_value : entry
        end
			end
		end
	end
end
