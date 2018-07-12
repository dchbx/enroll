module BenefitSponsors
  module Organizations
    class IssuerProfile < BenefitSponsors::Organizations::Profile
      include Mongoid::Document
      include Mongoid::Timestamps
      include Config::AcaModelConcern

      field :hbx_carrier_id, type: Integer

      field :abbrev, type: String
      field :associated_carrier_profile_id, type: BSON::ObjectId

      field :ivl_health, type: Boolean
      field :ivl_dental, type: Boolean
      field :shop_health, type: Boolean
      field :shop_dental, type: Boolean
      field :offers_sole_source, type: Boolean, default: false

      field :issuer_hios_ids, type: Array, default: []
      field :issuer_state, type: String, default: aca_state_abbreviation
      field :market_coverage, type: String, default: "shop (small group)" # or individual
      field :dental_only_plan, type: Boolean, default: false

      def benefit_products
      end

      def benefit_products_by_effective_date(effective_date)
      end

      private 

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, false)
        @is_benefit_sponsorship_eligible = false
        self
      end

      class << self

        def find_by_issuer_name(issuer_name)
          issuer_org = BenefitSponsors::Organizations::Organization.where(:legal_name => issuer_name, :"profiles._type" => "BenefitSponsors::Organizations::IssuerProfile").first
          issuer_org.profiles.where(:"_type" => "BenefitSponsors::Organizations::IssuerProfile").first
        end

        def find_by_abbrev(abbrev)
          issuer_org = BenefitSponsors::Organizations::Organization.where(:"profiles.abbrev" => abbrev, :"profiles._type" => "BenefitSponsors::Organizations::IssuerProfile").first
          issuer_org.profiles.where(:"_type" => "BenefitSponsors::Organizations::IssuerProfile").first
        end
      end
    end 
  end
end
