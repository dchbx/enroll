module BenefitSponsors
  module Organizations
    class GeneralAgencyProfile < BenefitSponsors::Organizations::Profile
      include ::SetCurrentUser
      include AASM
      include ::Config::AcaModelConcern

      MARKET_KINDS = individual_market_is_enabled? ? [:individual, :shop, :both] : [:shop]

      ALL_MARKET_KINDS_OPTIONS = {
        "Individual & Family Marketplace ONLY" => "individual",
        "Small Business Marketplace ONLY" => "shop",
        "Both – Individual & Family AND Small Business Marketplaces" => "both"
      }

      MARKET_KINDS_OPTIONS = ALL_MARKET_KINDS_OPTIONS.select { |k,v| MARKET_KINDS.include? v.to_sym }

      field :market_kind, type: Symbol
      field :corporate_npn, type: String
      field :primary_broker_role_id, type: BSON::ObjectId
      field :default_general_agency_profile_id, type: BSON::ObjectId

      field :languages_spoken, type: Array, default: ["en"] # TODO
      field :working_hours, type: Boolean, default: false
      field :accept_new_clients, type: Boolean
      field :aasm_state, type: String, default: 'is_applicant'
      field :aasm_state_set_on, type: Date

      field :home_page, type: String

      # embeds_many :documents, as: :documentable
      accepts_nested_attributes_for :inbox

      has_many :general_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
      accepts_nested_attributes_for :general_agency_contacts, reject_if: :all_blank, allow_destroy: true

      validates_presence_of :market_kind

      validates :corporate_npn,
        numericality: {only_integer: true},
        length: { minimum: 1, maximum: 10 },
        uniqueness: true,
        allow_blank: true

      validates :market_kind,
        inclusion: { in: Organizations::GeneralAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid practice area" },
        allow_blank: false

      after_initialize :build_nested_models

      scope :active,      ->{ any_in(aasm_state: ["is_applicant", "is_approved"]) }
      scope :inactive,    ->{ any_in(aasm_state: ["is_rejected", "is_suspended", "is_closed"]) }

      def employer_clients
      end

      def family_clients
      end

      def market_kinds
        MARKET_KINDS_OPTIONS
      end

      def language_options
        LanguageList::COMMON_LANGUAGES
      end

      def primary_staff
        # TODO: need replace this with general_agency_primary_staff
        general_agency_staff_roles.present? ? general_agency_staff_roles.last : nil
      end

      def general_agency_primary_staff
        general_agency_staff_roles.present? ? general_agency_staff_roles.select { |role| role.is_primary }.first : nil
      end

      def current_staff_state
        primary_staff.current_state rescue ""
      end

      def current_state
        aasm_state.humanize.titleize
      end

      def general_agency_staff_roles
        Person.where("general_agency_staff_roles.benefit_sponsors_general_agency_profile_id" => BSON::ObjectId.from_string(self.id)).map {|p| p.general_agency_staff_roles.detect {|s| s.benefit_sponsors_general_agency_profile_id == id}}
      end

      def languages
        if languages_spoken.any?
          return languages_spoken.map {|lan| LanguageList::LanguageInfo.find(lan).name if LanguageList::LanguageInfo.find(lan)}.compact.join(",")
        end
      end

      def primary_office_location
        office_locations.detect(&:is_primary?)
      end

      def commission_statements
        documents.where(subject: "commission-statement")
      end

      def phone
        office = primary_office_location
        office && office.phone.to_s
      end

      class << self
        def find(id)
          organization = BenefitSponsors::Organizations::Organization.where(
            "profiles._id" => BSON::ObjectId.from_string(id)
          ).first

          organization.profiles.where(id: BSON::ObjectId.from_string(id)).first if organization.present?
        end

        def list_embedded(parent_list)
          parent_list.reduce([]) { |list, parent_instance| list << parent_instance.general_agency_profile }
        end

        def all
          list_embedded BenefitSponsors::Organizations::Organization.general_agency_profiles.order_by([:legal_name]).to_a
        end

        def filter_by(status="is_applicant")
          if status == 'all'
            all
          else
            list_embedded BenefitSponsors::Organizations::Organization.general_agency_profiles.where(:'profiles.aasm_state' => status).order_by([:legal_name]).to_a
          end
        rescue
          []
        end

        def all_by_broker_role(broker_role, options={})
          favorite_general_agency_ids = broker_role.favorite_general_agencies.map(&:benefit_sponsors_general_agency_profile_id) rescue []
          all_ga = if options[:approved_only]
                     all.select{|ga| ga.aasm_state == 'is_approved'}
                   else
                     all
                   end

          if favorite_general_agency_ids.present?
            all_ga.sort {|ga| favorite_general_agency_ids.include?(ga.id) ? 0 : 1 }
          else
            all_ga
          end
        end
      end

      aasm do #no_direct_assignment: true do
        state :is_applicant, initial: true
        state :is_approved
        state :is_rejected
        state :is_suspended
        state :is_closed

        event :approve do
          transitions from: [:is_applicant, :is_suspended], to: :is_approved
        end

        event :reject do
          transitions from: :is_applicant, to: :is_rejected
        end

        event :suspend do
          transitions from: [:is_applicant, :is_approved], to: :is_suspended
        end

        event :close do
          transitions from: [:is_approved, :is_suspended], to: :is_closed
        end
      end

      def applicant?
        aasm_state == "is_applicant"
      end

      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, false)
        @is_benefit_sponsorship_eligible = false
        self
      end

      def build_nested_models
        build_inbox if inbox.nil?
      end

    end
  end
end
