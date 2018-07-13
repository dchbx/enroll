module BenefitSponsors
  class SponsoredBenefits::SponsorContribution

    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Attributes::Dynamic

    embedded_in :sponsored_benefit,
      class_name: "BenefitSponsors::SponsoredBenefits::SponsoredBenefit"
    embeds_many :contribution_levels,
                class_name: "BenefitSponsors::SponsoredBenefits::ContributionLevel"

    delegate :contribution_model, to: :sponsored_benefit
    delegate :reference_product, to: :sponsored_benefit, allow_nil: false
    delegate :recorded_sic_code, to: :sponsored_benefit
    
    accepts_nested_attributes_for :contribution_levels
#    validates_presence_of :contribution_levels
#    validate :validate_contribution_levels

    # def validate_contribution_levels
    #   true
    # end

    def sic_code
      recorded_sic_code
    end

    # FIXME: This is wrong and only does the worlds dumbest pairing
    #        by position. This DOES NOT WORK for the non-composite
    #        cases.
    def match_contribution_level_for(pricing_unit)
      cl_list = contribution_levels.to_a.sort_by(&:order)
      possible_cl = cl_list[pricing_unit.order]
      possible_cl ? possible_cl : cl_list.last
    end

    def self.sponsor_contribution_for(new_product_package)
      contribution_service = BenefitSponsors::SponsoredBenefits::ProductPackageToSponsorContributionService.new
      contribution_service.build_sponsor_contribution(new_product_package)
    end

    def renew(new_product_package)
      new_sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(new_product_package)
      new_sponsor_contribution.contribution_levels.each do |new_contribution_level|
        current_contribution_level = contribution_levels.detect{|cl| cl.display_name == new_contribution_level.display_name}
        # TODO: Fix this so that this copies all relevent attributes.
        if current_contribution_level.present?
          new_contribution_level.is_offered = current_contribution_level.is_offered
          new_contribution_level.contribution_factor = current_contribution_level.contribution_factor
        end
      end
      new_sponsor_contribution
    end
  end
end
