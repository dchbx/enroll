module BenefitMarkets
  module Products
    module ActuarialFactors
      class SicActuarialFactor < ActuarialFactor
        def self.value_for(carrier_profile_id, year, val)
          record = self.where(issuer_profile_id: carrier_profile_id, active_year: year).first
          record.lookup(val)
        end
      end
    end
  end
end
