module SponsoredBenefits
  module RatingModels
    class RatingModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hbx_id,                type: String
      field :title,                 type: String
      field :description,           type: String, default: ""

      field :credit_structure_kind, type: Symbol

      belongs_to  :benefit_catalog,       class_name: "SponsoredBenefits::BenefitCatalogs::BenefitCatalog"
      has_many    :products


      embeds_many :rating_tiers,          class_name: "SponsoredBenefits::RatingModels::RatingTier"
      embeds_many :rating_factors,        class_name: "SponsoredBenefits::RatingModels::RatingFactor"

      # embeds_many :rating_areas,    class_name: "SponsoredBenefits::Locations::RatingArea"

      validates :credit_structure_kind,
        inclusion:  { in: CreditStructure::KINDS, message: "%{value} is not a valid credit structure kind" },
        allow_nil:  false

      validates_presense_of :hbx_id, :title


      def rating_tier_for(enrollment_group)
        rating_tiers.match(enrollment_group)
      end

=begin
      class benefit_package
        embeds_many :benefit_designs
        embeds_one  :roster
      end

      class health_benefit_design < benefit_design

        embeds_one :product_set
        embeds_one :reference_plan
        embeds_one :rating_model
      end

=end
# benefit_sponsor

# BenefitApplication
#   probation_period
#   effective_period
#   open_enrollment_period
#   fte_count
#   pte_count
#   msp_sount
# BenefitPackage
#   Roster
# HealthBenefitDesign
  


#             "start_on"=>"2018-05-01", "end_on"=>"2019-04-30", "open_enrollment_start_on"=>"2018-03-14", "open_enrollment_end_on"=>"2018-04-10", "fte_count"=>"25", "pte_count"=>"10", "msp_count"=>"0",
#             "benefit_groups_attributes" => {
#              "0"=>{"title"=>"New Benefit Group", "description"=>"First Benefit Group", "effective_on_offset"=>"0", 
#                "relationship_benefits_attributes"=>
#                {"0"=>{"relationship"=>"employee", "premium_pct"=>"80"}, 
#                "1"=>{"offered"=>"true", "relationship"=>"spouse", "premium_pct"=>"70"}, 
#                "2"=>{"offered"=>"true", "relationship"=>"domestic_partner", "premium_pct"=>"0"}, 
#                "3"=>{"offered"=>"true", "relationship"=>"child_under_26", "premium_pct"=>"0"}, 
#                "4"=>{"offered"=>"false", "relationship"=>"child_26_and_over", "premium_pct"=>"0"}},
#                "effective_on_kind"=>"first_of_month",
#                "plan_option_kind"=>"single_carrier",
#                "carrier_for_elected_plan"=>"53e67210eb899a460300000d",
#                "reference_plan_id"=>"59f72cf1faca145fb8005c08",

#                "dental_relationship_benefits_attributes"=>{
#                 "0"=>{"offered"=>"true", "relationship"=>"employee", "premium_pct"=>"0"},
#                 "1"=>{"offered"=>"true", "relationship"=>"spouse", "premium_pct"=>"0"},
#                 "2"=>{"offered"=>"true", "relationship"=>"domestic_partner", "premium_pct"=>"0"},
#                 "3"=>{"offered"=>"true", "relationship"=>"child_under_26", "premium_pct"=>"0"},
#                 "4"=>{"offered"=>"false", "relationship"=>"child_26_and_over", "premium_pct"=>"0"}},
#                "carrier_for_elected_dental_plan"=>"", "dental_reference_plan_id"=>"", "dental_relationship_benefits_attributes_time"=>"0"}



      def set_sponsor_contribution_amounts
      end

      def assign_roster_members_to_rating_tier
      end

      def calculate_contributions
      end

      def validate_benefit_market_constraints
      end


    end
  end
end
