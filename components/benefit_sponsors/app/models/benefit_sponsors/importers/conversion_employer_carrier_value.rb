module Importers::ConversionEmployerCarrierValue

  def self.included(base)
    base.class_eval do
      attr_reader :carrier

      validate :validate_carrier
      validates_presence_of :carrier, :allow_blank => false
    end
  end

  def carrier=(val)
    return @carrier if defined? @carrier
    if val.blank?
      @carrier = nil
      return val
    end
    @carrier = val
  end

  def validate_carrier
    found_carrier = find_carrier
    if found_carrier.nil?
      errors.add(:carrier, "invalid carrier specified (not one of #{self.class::CARRIER_MAPPING.keys.join(", ")})")
    end
  end

  def find_carrier
    carrier = BenefitSponsors::Organizations::IssuerProfile.find_by_issuer_name("Fallon Health")
    # return nil unless carrier
  end

end
