module SponsoredBenefits
  module Organizations
    class PlanDesignProposal
      include Mongoid::Document
      include Mongoid::Timestamps
      include AASM

      RENEWAL_STATES = %w(renewing_draft renewing_published renewing_claimed renewing_expired)
      EXPIRABLE_STATES = %w(draft renewing_draft)

      embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

      field :title, type: String
      field :submitted_date, type: Date

      field :claim_code, type: String
      field :claim_date, type: Date
      field :published_on, type: Date
      field :aasm_state, type: String

      embeds_one :profile, class_name: "SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile"
      delegate :effective_date, to: :profile
      validates_uniqueness_of :claim_code, :case_sensitive => false, :allow_nil => true

      scope :datatable_search, ->(query) { self.where({"$or" => ([{"title" => ::Regexp.compile(::Regexp.escape(query), true)}])}) }
      ## TODO: how are we defining 'initial' vs 'renewing'?
      scope :initial, -> { not_in(aasm_state: RENEWAL_STATES) }
      scope :renewing, ->{ any_in(aasm_state: RENEWAL_STATES) }
      scope :draft, -> { any_in(aasm_state: %w(draft renewing_draft)) }
      scope :published, -> { any_in(aasm_state: %w(published renewing_published)) }
      scope :expired, -> { any_in(aasm_state: %w(expired renewing_expired)) }
      scope :claimed, -> { any_in(aasm_state: %w(claimed renewing_claimed)) }

      def active_benefit_group
        return nil if profile.nil?
        return nil if profile.benefit_sponsorships.empty?
        sponsorship = profile.benefit_sponsorships.first
        return nil if sponsorship.benefit_applications.empty?
        application = sponsorship.benefit_applications.first
        return nil if application.benefit_groups.empty?
        application.benefit_groups.first
      end

      def active_census_employees
        return nil if profile.benefit_sponsorships.empty?
        sponsorship = profile.benefit_sponsorships.first
        sponsorship.census_employees
      end

      def active_census_familes
        active_census_employees.where({ "census_dependents.0" => { "$exists" => true } })
      end

      # class methods
      class << self

        # find plan_design_proposal object by id
        def find(id)
          organization = SponsoredBenefits::Organizations::PlanDesignOrganization.where("plan_design_proposals._id" => BSON::ObjectId.from_string(id)).first
          organization.plan_design_proposals.detect{|proposal| proposal.id == BSON::ObjectId.from_string(id)}
        end

        # find plan_design_proposal object by claim_code
        def find_quote(quote_claim_code)
          # search plan_design_proposal with published status and user entered claim code.
          organization = SponsoredBenefits::Organizations::PlanDesignOrganization.where(
            "plan_design_proposals.aasm_state" => "published",
            "plan_design_proposals.claim_code" => quote_claim_code
          ).first

          return nil if organization.blank?

          # retrieve the quote that the user entered to claim on the benefits page in employer portal.
          organization.plan_design_proposals.detect{ |pdp| pdp.claim_code == quote_claim_code }
        end

        def claim_code_status?(quote_claim_code)
          quote = find_quote(quote_claim_code) # search for the quote that is in published status
          if quote.present?
            return [quote.aasm_state, quote] # quote is present, return its current status.
          else
            return "invalid" # quote is not present, return invalid(replicating the same functionality as in dc enroll.)
          end
        end


        # this method creates a draft plan year from a valid claim code entered on benefits page(in employer portal).
        def build_plan_year_from_quote(employer_profile, quote)
          builder = SponsoredBenefits::BenefitApplications::EmployerProfileBuilder.new(quote, employer_profile)
          if builder.quote_valid?
            builder.add_plan_year
            # builder.add_census_members
            quote.claim_date = TimeKeeper.date_of_record
            quote.claim!
          end
        end
      end

      def can_quote_be_published?
        self.valid?
      end

      def can_be_expired?
        self.valid? && !plan_design_organization.is_prospect?
      end

      def generate_character
        ascii = rand(36) + 48
        ascii += 39 if ascii >= 58
        ascii.chr.upcase
      end

      def employer_claim_code
        4.times.map{generate_character}.join + '-' + 4.times.map{generate_character}.join
      end

      def set_employer_claim_code
        self.claim_code = employer_claim_code
        self.published_on = TimeKeeper.date_of_record
        self.save!
      end

      aasm do
        state :draft, initial: true
        state :published
        state :claimed
        state :expired
        state :renewing_draft
        state :renewing_published
        state :renewing_claimed
        state :renewing_expired

        event :publish do
          transitions from: :draft, to: :published, :guard => "can_quote_be_published?", after: :set_employer_claim_code
        end

        event :claim do
          transitions from: :published, to: :claimed
        end

        event :expire do
          transitions from: :draft, to: :expired, :guard => :can_be_expired?
          transitions from: :renewing_draft, to: :renewing_expired, :guard => :can_be_expired?
        end
      end

    end
  end
end
