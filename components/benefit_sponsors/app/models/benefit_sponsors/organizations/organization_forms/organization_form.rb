# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    class OrganizationForms::OrganizationForm
      include ActiveModel::Validations
      include ::Validations::Email
      include BenefitSponsors::Forms::NpnField
      extend  ActiveModel::Naming
      include ActiveModel::Conversion
      include Virtus.model

      attribute :fein, String
      attribute :legal_name, String
      attribute :dba, String
      attribute :entity_kind, Symbol, default: :s_corporation #TODO
      attribute :entity_kind_options, Array
      attribute :profile_type, String

      attribute :profile, OrganizationForms::ProfileForm

      validates :fein,
                length: { is: 9, message: "%{value} is not a valid FEIN" },
                numericality: true, if: :is_employer_profile?

      validates_presence_of :entity_kind, :legal_name
      validates_presence_of :fein, if: :is_employer_profile?

      def persisted?
        false
      end

      def legal_name=(val)
        legal_name = val.blank? ? nil : val.strip
        super legal_name
      end

      # Strip non-numeric characters
      def fein=(new_fein)
        fein = begin
                 new_fein.to_s.gsub(/\D/, '')
               rescue StandardError
                 nil
               end
        super fein
      end

      def is_broker_profile?
        profile.try(:profile_type) == "broker_agency"
      end

      def is_general_agency_profile?
        profile.try(:profile_type) == "general_agency"
      end

      def is_employer_profile?
        profile.try(:profile_type) == "benefit_sponsor"
      end

      def profile_attributes=(profile_params)
        self.profile = profile_params
      end

      def profile=(val)
        result = super val
        result.parent = self
        result
      end
    end
  end
end
