module BenefitSponsors
  module Organizations
    class OrganizationForms::ProfileForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String
      attribute :market_kind, Symbol
      attribute :is_benefit_sponsorship_eligible, String
      attribute :corporate_npn, String
      attribute :languages_spoken, String
      attribute :working_hours, Boolean
      attribute :accept_new_clients, Boolean
      attribute :home_page, String
      attribute :contact_method, String
      attribute :market_kind_options, Hash
      attribute :grouped_sic_code_options, Hash
      attribute :language_options, Array
      attribute :contact_method_options, Hash
      attribute :profile_type, String
      attribute :sic_code, String
      attribute :inbox, OrganizationForms::InboxForm
      attribute :parent, OrganizationForms::OrganizationForm
      attribute :ach_account_number, String
      attribute :ach_routing_number, String
      attribute :ach_routing_number_confirmation, String

      attribute :office_locations, Array[OrganizationForms::OfficeLocationForm]

      validates_presence_of :market_kind, if: :is_broker_profile?
      validates_presence_of :ach_routing_number, if: :is_broker_profile?

      validate :validate_profile_office_locations
      validate :validate_routing_information, if: :is_broker_profile?

      def persisted?
        false
      end

      def office_locations_attributes=(locations_params)
        self.office_locations=(locations_params.values)
      end

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_employer_profile?
        profile_type == "benefit_sponsor"
      end

      def validate_routing_information
        if ach_routing_number.present? && !(ach_routing_number == ach_routing_number_confirmation)
          self.errors.add(:base, "can't have two different routing numbers, please make sure you have same routing numbers on both fields")
        end
      end

      def validate_profile_office_locations
        location_kinds = self.office_locations.flat_map(&:address).compact.flat_map(&:kind)
        if location_kinds.count('primary').zero?
          self.errors.add(:base, "must select one primary address")
        elsif location_kinds.count('primary') > 1
          self.errors.add(:base, "can't have multiple primary addresses")
        elsif location_kinds.count('mailing') > 1
          self.errors.add(:base, "can't have more than one mailing address")
        end
      end

    end
  end
end
