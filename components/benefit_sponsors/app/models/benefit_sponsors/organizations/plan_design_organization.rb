# Broker-owned model to manage attributes of the prospective of existing employer
module BenefitSponsors
  module Organizations
    class PlanDesignOrganization < BenefitSponsors::Organizations::Organization


      belongs_to  :plan_design_organization, inverse_of: :plan_design_organizations, counter_cache: true,
                  class_name: "BenefitSponsors::Organizations::Organization"

      belongs_to  :subject_organization, inverse_of: :plan_design_subject_organizations,
                  class_name: "BenefitSponsors::Organizations::Organization"

      embeds_many :plan_design_proposals, class_name: "BenefitSponsors::Organizations::PlanDesignProposal", cascade_callbacks: true

      
      validates_presence_of :subject_organization

      index({"subject_organization._id" => 1})
      index({"plan_design_proposals._id" => 1})
      index({"plan_design_proposals.aasm_state" => 1, "plan_design_proposals.claim_code" => 1})

      scope :by_subject_organization,  ->(subject_organization){ where(:"subject_organization_id" => BSON::ObjectId.from_string(subject_organization)) }

      # scope :find_by_proposal,     ->(proposal) { where(:"plan_design_proposal._id" => BSON::ObjectId.from_string(proposal)) }

      # scope :active_sponsors,     -> { where(:has_active_broker_relationship => true) }
      # scope :inactive_sponsors,   -> { where(:has_active_broker_relationship => false) }
      # scope :prospect_sponsors,   -> { where(:sponsor_profile_id => nil) }

      scope :draft_proposals,     -> { where(:'plan_design_proposals.aasm_state' => 'draft')}

      scope :datatable_search,    -> (query) { self.where({"$or" => ([{"legal_name" => ::Regexp.compile(::Regexp.escape(query), true)}, 
                                                                      {"fein" => ::Regexp.compile(::Regexp.escape(query), true)}])}) }


      # TODO Move this method to BenefitMarket Model
      def service_areas_available_on(date)
        if use_simple_employer_calculation_model?
          return []
        end
        ::CarrierServiceArea.service_areas_available_on(primary_office_location.address, date.year)
      end

      def broker_relationship_inactive?
        !has_active_broker_relationship
      end

      def is_prospect?
        sponsor_profile_id.nil?
      end

      def expire_proposals
        plan_design_proposals.each do |proposal|
          proposal.expire! if BenefitSponsors::Organizations::PlanDesignProposal::EXPIRABLE_STATES.include? proposal.aasm_state
        end
      end

      def calculate_start_on_options
        calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      end

      def calculate_start_on_dates
        if employer_profile.present? && employer_profile.active_plan_year.present?
          [employer_profile.active_plan_year.start_on.next_year]
        else
          BenefitSponsors::BenefitApplications::BenefitApplication.calculate_start_on_dates
        end
      end

      def new_proposal_state
        if employer_profile.present? && employer_profile.active_plan_year.present?
          'renewing_draft'
        else
          'draft'
        end
      end

      def build_proposal_from_existing_employer_profile

        # TODO Use Subclass that belongs to this set, e.g. BenefitSponsors::BenefitApplications::AcaShopCcaPlanDesignProposalBuilder

        builder = BenefitSponsors::BenefitApplications::PlanDesignProposalBuilder.new(self, calculate_start_on_dates[0])
        builder.add_plan_design_profile
        builder.add_benefit_application
        builder.add_plan_design_employees
        builder.plan_design_organization.save
        builder.census_employees.each{|ce| ce.save}
        builder.add_proposal_state(new_proposal_state)
        builder.plan_design_proposal
      end

      class << self
        #TODO Pass object instances, not IDs
        def find_by_owner_and_sponsor(owner_id, sponsor_id)
          where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id), :"sponsor_profile_id" => BSON::ObjectId.from_string(sponsor_id)).first
        end
      end

    end
  end
end
