# BenefitSponsorship
# Manage enrollment-related behavior for a benefit-sponsoring organization (e.g. employers, congress, HBX, etc.)
# The model design assumes a once annual enrollment period and effective date.  For scenarios where there's a once-yearly
# open enrollment, new sponsors may join mid-year for initial enrollment, subsequently renewing on-schedule in following
# cycles.  Scenarios where enollments are conducted on a rolling monthly basis are also supported.

# Organzations may embed many BenefitSponsorships.  Significant changes result in new BenefitSponsorship,
# such as the following supported scenarios:
# - Benefit Sponsor (employer) voluntarily terminates and later returns after some elapsed period
# - Benefit Sponsor is involuntarily terminated (such as for non-payment) and later becomes eligible
# - Existing Benefit Sponsor changes effective date

# Referencing a new BenefitSponsorship helps ensure integrity on subclassed and associated data models and
# enables history tracking as part of the models structure
module BenefitSponsors
  module BenefitSponsorships
    class BenefitSponsorship
      include Mongoid::Document
      include Mongoid::Timestamps
      # include Concerns::Observable
      include AASM

      SOURCE_KINDS  = %w(self_serve conversion)


      field :hbx_id,            type: String
      field :profile_id,        type: BSON::ObjectId
      field :contact_method,    type: Symbol, default: :paper_and_electronic

      # Effective begin/end are the date period during which this benefit sponsorship is active.  
      # effective_begin_on is date with initial application coverage effectuates
      # effective_end_on reflects date when all benefit applications are terminate and sponsorship terminates
      field :effective_begin_on,  type: Date
      field :effective_end_on,    type: Date


      field :source_kind,   type: String, default: :self_serve
      field :registered_on, type: Date, default: ->{ TimeKeeper.date_of_record }


      # This sponsorship's workflow status
      field :aasm_state,    type: String, default: :applicant do
        error_on_all_events { |e| raise WMS::MovementError.new(e.message, original_exception: e, model: self) }
      end

      delegate :sic_code,     :sic_code=,     to: :profile, allow_nil: true
      delegate :rating_area,  :rating_area=,  to: :profile, allow_nil: true


      belongs_to  :organization, 
                  inverse_of: :benefit_sponorships, 
                  counter_cache: true,
                  class_name: "BenefitSponsors::Organizations::Organization"

      has_many    :benefit_applications,
                  class_name: "BenefitSponsors::BenefitApplications::BenefitApplication"

      belongs_to  :benefit_market, 
                  counter_cache: true,
                  class_name: "::BenefitMarkets::BenefitMarket"

      has_many    :service_areas, 
                  class_name: "::BenefitMarkets::Locations::ServiceArea"

      embeds_many :broker_agency_accounts,
                  class_name: "::BenefitSponsors::Accounts::BrokerAgencyAccount",
                  validate: true

      embeds_many :general_agency_accounts,
                  class_name: "::BenefitSponsors::Accounts::GeneralAgencyAccount",
                  validate: true

      has_many    :documents,
                  inverse_of: :benefit_sponsorship_docs,
                  class_name: "BenefitSponsors::Documents::Document"


      validates_presence_of :organization, :profile_id, :benefit_market

      validates :contact_method,
        inclusion: { in: ::BenefitMarkets::CONTACT_METHOD_KINDS, message: "%{value} is not a valid contact method" },
        allow_blank: false

      validates :source_kind,
        inclusion: { in: SOURCE_KINDS, message: "%{value} is not a valid source kind" },
        allow_blank: false


      before_create :generate_hbx_id

      index({ aasm_state: 1 })

      # Inverse of Profile#benefit_sponsorship
      def profile
        return @profile if defined?(@profile)
        @profile = organization.profiles.detect { |profile| profile._id == self.profile_id }
      end

      def profile=(profile)
        write_attribute(:profile_id, profile._id)
        @profile = profile
      end


      # TODO: add find_by_benefit_sponsorhip scope to CensusEmployee
      def census_employees
        return @census_employees if is_defined?(@census_employees)
        @census_employees = ::CensusEmployee.find_by_benefit_sponsorship(self)
      end

      # TODO - turn this in to counter_cache -- see: https://gist.github.com/andreychernih/1082313
      def roster_size
        return @roster_size if defined? @roster_size
        @roster_size = census_employees.active.size
      end


      # Workflow for self service
      aasm do
        state :applicant, initial: true
        state :registered                 # Employer has submitted valid application
        state :eligible                   # Employer has completed enrollment and is eligible for coverage
        state :binder_paid, :after_enter => [:notify_binder_paid,:notify_initial_binder_paid]
        state :enrolled                   # Employer has completed eligible enrollment, paid the binder payment and plan year has begun
      # state :lapsed                     # Employer benefit coverage has reached end of term without renewal
        state :suspended                  # Employer's benefit coverage has lapsed due to non-payment
        state :ineligible                 # Employer is unable to obtain coverage on the HBX per regulation or policy

        state :terminated_involuntarily   # Employer is unable to obtain coverage on the HBX per regulation or policy
        state :voluntarily_terminated     # Employer is unable to obtain coverage on the HBX per regulation or policy


        event :application_accepted, :after => :record_transition do
          transitions from: [:registered], to: :registered
          transitions from: [:applicant, :ineligible], to: :registered
        end

      end

      class << self
        def find_broker_for_sponsorship(id)
          organization = nil
          Organizations::PlanDesignOrganization.all.each do |pdo|
            sponsorships = pdo.plan_design_profile.try(:benefit_sponsorships) || []
            organization = pdo if sponsorships.any? { |sponsorship| sponsorship._id == BSON::ObjectId.from_string(id)}
          end
          organization
        end
      end


      private

      def generate_hbx_id
        write_attribute(:hbx_id, BenefitSponsors::Organizations::HbxIdGenerator.generate_benefit_sponsorship_id) if hbx_id.blank?
      end

    end
  end
end
