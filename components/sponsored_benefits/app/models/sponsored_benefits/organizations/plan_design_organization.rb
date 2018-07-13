# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization
      include Mongoid::Document
      include Mongoid::Timestamps
      include Concerns::OrganizationConcern
      include Concerns::AcaRatingAreaConfigConcern

      belongs_to :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile", inverse_of: 'plan_design_organization'

      # Registered legal name
      field :legal_name, type: String

      # Doing Business As (alternate name)
      field :dba, type: String

      # Federal Employer ID Number
      field :fein, type: String

      # Standard Industrial Classification Code that indicates company's business type
      field :sic_code, type: String

      # Plan design owner profile type & ID
      field :owner_profile_id,    type: BSON::ObjectId
      field :owner_profile_class_name,  type: String, default: "::BenefitSponsors::Organizations::Profile"

      # Plan design sponsor profile type & ID
      field :sponsor_profile_id,         type: BSON::ObjectId
      field :sponsor_profile_class_name, type: String, default: "::BenefitSponsors::Organizations::Profile"

      #temporary fields to store old model profile data as history while migrating
      field :past_owner_profile_id,type: BSON::ObjectId
      field :past_owner_profile_class_name,type: String
      field :past_sponsor_profile_id,type: BSON::ObjectId
      field :past_sponsor_profile_class_name,type: String

      field :has_active_broker_relationship, type: Boolean, default: false

      embeds_many :plan_design_proposals, class_name: "SponsoredBenefits::Organizations::PlanDesignProposal", cascade_callbacks: true

      validates_presence_of   :legal_name, :has_active_broker_relationship
      validates_presence_of :sic_code, if: :sic_code_exists_for_employer?
      validates_uniqueness_of :owner_profile_id, :scope => :sponsor_profile_id, unless: Proc.new { |pdo| pdo.sponsor_profile_id.nil? }
      validates_uniqueness_of :sponsor_profile_id, :scope => :owner_profile_id, unless: Proc.new { |pdo| pdo.sponsor_profile_id.nil? }


      index({"owner_profile_id" => 1})
      index({"sponsor_profile_id" => 1})
      index({"has_active_broker_relationship" => 1})
      index({"plan_design_proposals._id" => 1})
      index({"plan_design_proposals.aasm_state" => 1, "plan_design_proposals.claim_code" => 1})


      # TODO These scopes must use both the Profile Class and ID.  Change to pass in profile instance
      scope :find_by_owner,       -> (owner_id) { where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id)) }
      scope :find_by_sponsor,     -> (sponsor_id) { where(:"sponsor_profile_id" => BSON::ObjectId.from_string(sponsor_id)) }

      scope :find_by_proposal,    -> (proposal) { where(:"plan_design_proposal._id" => BSON::ObjectId.from_string(proposal)) }

      scope :active_sponsors,     -> { where(:has_active_broker_relationship => true) }
      scope :inactive_sponsors,   -> { where(:has_active_broker_relationship => false) }
      scope :prospect_sponsors,   -> { where(:sponsor_profile_id => nil) }

      scope :draft_proposals,     -> { where(:'plan_design_proposals.aasm_state' => 'draft')}

      scope :datatable_search,    -> (query) { self.where({"$or" => ([{"legal_name" => ::Regexp.compile(::Regexp.escape(query), true)},
                                                                      {"fein" => ::Regexp.compile(::Regexp.escape(query), true)}])}) }



      def employer_profile
        ::EmployerProfile.find(sponsor_profile_id) || ::BenefitSponsors::Organizations::Profile.find(sponsor_profile_id)
      end

      def broker_agency_profile
        ::BrokerAgencyProfile.find(owner_profile_id) || ::BenefitSponsors::Organizations::Profile.find(owner_profile_id)
      end

      def general_agency_profile
        self.try(:employer_profile).try(:active_general_agency_account)
      end

      def active_employer_benefit_sponsorship
        bs = employer_profile.active_benefit_sponsorship
        bs if (bs && bs.is_eligible?)
      end

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
          proposal.expire! if SponsoredBenefits::Organizations::PlanDesignProposal::EXPIRABLE_STATES.include? proposal.aasm_state
        end
      end

      def calculate_start_on_options
        calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      end

      def calculate_start_on_dates
        if employer_profile.present? && employer_profile.active_plan_year.present?
          [employer_profile.active_plan_year.end_on.to_date.next_day]
        else
          SponsoredBenefits::BenefitApplications::BenefitApplication.calculate_start_on_dates
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

        # TODO Use Subclass that belongs to this set, e.g. SponsoredBenefits::BenefitApplications::AcaShopCcaPlanDesignProposalBuilder

        builder = SponsoredBenefits::BenefitApplications::PlanDesignProposalBuilder.new(self, calculate_start_on_dates[0])
        builder.add_plan_design_profile
        builder.add_benefit_application
        builder.add_plan_design_employees
        builder.plan_design_organization.save
        builder.census_employees.each{|ce| ce.save}
        builder.add_proposal_state(new_proposal_state)
        builder.plan_design_proposal
      end

      def sic_code_exists_for_employer?
        Settings.aca.employer_has_sic_field
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
