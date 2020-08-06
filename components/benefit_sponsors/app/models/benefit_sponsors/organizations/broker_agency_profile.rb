# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    class BrokerAgencyProfile < BenefitSponsors::Organizations::Profile
      include ::SetCurrentUser
      include AASM
      include ::Config::AcaModelConcern
      include Acapi::Notifiers
      include ::BenefitSponsors::Concerns::Observable
      include ::BenefitSponsors::ModelEvents::BrokerAgencyProfile

      MARKET_KINDS = individual_market_is_enabled? ? [:individual, :shop, :both] : [:shop]

      ALL_MARKET_KINDS_OPTIONS = {
        "Individual & Family Marketplace ONLY" => "individual",
        "Small Business Marketplace ONLY" => "shop",
        "Both – Individual & Family AND Small Business Marketplaces" => "both"
      }.freeze

      MARKET_KINDS_OPTIONS = ALL_MARKET_KINDS_OPTIONS.select { |_k,v| MARKET_KINDS.include? v.to_sym }

      field :market_kind, type: Symbol
      field :corporate_npn, type: String
      field :primary_broker_role_id, type: BSON::ObjectId
      field :default_general_agency_profile_id, type: BSON::ObjectId

      field :languages_spoken, type: Array, default: ["en"] # TODO
      field :working_hours, type: Boolean, default: false
      field :accept_new_clients, type: Boolean

      field :ach_routing_number, type: String
      field :ach_account_number, type: String

      field :aasm_state, type: String

      field :home_page, type: String

      # embeds_many :documents, as: :documentable
      accepts_nested_attributes_for :inbox

      has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
      accepts_nested_attributes_for :broker_agency_contacts, reject_if: :all_blank, allow_destroy: true

      validates_presence_of :market_kind

      validates :corporate_npn,
                numericality: {only_integer: true},
                length: { minimum: 1, maximum: 10 },
                uniqueness: true,
                allow_blank: true

      validates :market_kind,
                inclusion: { in: Organizations::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid practice area" },
                allow_blank: false

      before_save :notify_before_save

      add_observer ::BenefitSponsors::Observers::NoticeObserver.new, [:process_broker_agency_profile_events]

      after_initialize :build_nested_models

      scope :active,      ->{ any_in(aasm_state: ["is_applicant", "is_approved"]) }
      scope :inactive,    ->{ any_in(aasm_state: ["is_rejected", "is_suspended", "is_closed"]) }

      # has_one primary_broker_role
      def primary_broker_role=(new_primary_broker_role = nil)
        if new_primary_broker_role.present?
          raise ArgumentError, "expected BrokerRole class" unless new_primary_broker_role.is_a? BrokerRole
          self.primary_broker_role_id = new_primary_broker_role._id
        else
          unset("primary_broker_role_id")
        end
        @primary_broker_role = new_primary_broker_role
      end

      def primary_broker_role
        return @primary_broker_role if defined? @primary_broker_role
        @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
      end

      def active_broker_roles
        @active_broker_roles = BrokerRole.find_active_by_broker_agency_profile(self)
      end

      def employer_clients
        # return unless (MARKET_KINDS - ["individual"]).include?(market_kind)
        return @employer_clients if defined? @employer_clients
        @employer_clients = BenefitSponsors::Concerns::EmployerProfileConcern.find_by_broker_agency_profile(self)
      end

      def family_clients; end

      def market_kinds
        MARKET_KINDS_OPTIONS
      end

      def language_options
        LanguageList::COMMON_LANGUAGES
      end

      def languages
        if languages_spoken.any?
          languages_spoken.map {|lan| LanguageList::LanguageInfo.find(lan).name if LanguageList::LanguageInfo.find(lan)}.compact.join(",")
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

      def linked_employees
        employer_profiles = BenefitSponsors::Concerns::EmployerProfileConcern.find_by_broker_agency_profile(self)
        if employer_profiles
          emp_ids = employer_profiles.map(&:id)
          Person.where(:'employee_roles.benefit_sponsors_employer_profile_id'.in => emp_ids)
        end
      end

      def families
        linked_active_employees = linked_employees.select(&:has_active_employee_role?)
        employee_families = linked_active_employees.map(&:primary_family).to_a
        consumer_families = Family.by_broker_agency_profile_id(self.id).to_a
        families = (consumer_families + employee_families).uniq
        families.sort_by{|f| f.primary_applicant.person.last_name}
      end

      def default_general_agency_profile=(new_default_general_agency_profile = nil)
        if new_default_general_agency_profile.present?
          raise ArgumentError, "expected GeneralAgencyProfile class" unless new_default_general_agency_profile.is_a? BenefitSponsors::Organizations::GeneralAgencyProfile
          self.default_general_agency_profile_id = new_default_general_agency_profile.id
        else
          self.default_general_agency_profile_id = nil
        end
        @default_general_agency_profile = new_default_general_agency_profile
      end

      def default_general_agency_profile
        return @default_general_agency_profile if defined? @default_general_agency_profile
        @default_general_agency_profile = BenefitSponsors::Organizations::GeneralAgencyProfile.find(self.default_general_agency_profile_id) if default_general_agency_profile_id.present?
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
