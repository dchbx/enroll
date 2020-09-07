# frozen_string_literal: true

module FinancialAssistance
  module Forms
    class Applicant
      include ActiveModel::Model
      include ActiveModel::Validations
      include Config::AcaModelConcern

      attr_accessor :id, :family_id, :is_consumer_role, :is_resident_role, :vlp_document_id
      attr_accessor :application_id, :applicant_id
      attr_accessor :gender, :relationship
      attr_accessor :no_dc_address, :is_homeless, :is_temporarily_out_of_state, :same_with_primary, :is_applying_coverage
      attr_accessor :addresses, :phones, :emails
      attr_accessor :addresses_attributes, :phones_attributes, :emails_attributes

      attr_writer :family
      include ::Forms::PeopleNames
      include ::Forms::ConsumerFields
      include ::Forms::SsnField
      RELATIONSHIPS = ::PersonRelationship::Relationships + ::BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS
      #include ::Forms::DateOfBirthField
      #include Validations::USDate.on(:date_of_birth)
      # accepts_nested_attributes_for :addresses

      validates_presence_of :first_name, :allow_blank => nil
      validates_presence_of :last_name, :allow_blank => nil
      validates_presence_of :gender, :allow_blank => nil
      validates_presence_of :family_id, :allow_blank => nil
      validates_presence_of :dob
      validates_inclusion_of :relationship, :in => RELATIONSHIPS.uniq, :allow_blank => nil, message: ""
      validate :relationship_validation
      validate :consumer_fields_validation

      attr_reader :dob

      def initialize(*attributes)
        initialize_attributes
        super
      end

      def dob=(val)
        @dob = begin
          Date.strptime(val, "%Y-%m-%d")
        rescue StandardError # rubocop:disable Lint/EmptyRescueClause
          nil
        end
      end

      def initialize_attributes
        @addresses = %w[home mailing].collect{|kind| FinancialAssistance::Locations::Address.new(kind: kind) }
        @phones    = FinancialAssistance::Locations::Phone::KINDS.collect{|kind| FinancialAssistance::Locations::Phone.new(kind: kind) }
        @emails    = FinancialAssistance::Locations::Email::KINDS.collect{|kind| FinancialAssistance::Locations::Email.new(kind: kind) }
        @same_with_primary = "true"
        @is_applying_coverage = true
      end

      def consumer_fields_validation
        return true unless individual_market_is_enabled?
        return unless @is_consumer_role.to_s == "true" && is_applying_coverage.to_s == "true"

        validate_citizen_status
        self.errors.add(:base, "native american / alaskan native status is required") if @indian_tribe_member.nil?
        self.errors.add(:tribal_id, "is required when native american / alaskan native is selected") if !tribal_id.present? && @indian_tribe_member
        self.errors.add(:base, "Incarceration status is required") if @is_incarcerated.nil?
      end

      def validate_citizen_status
        error_message = if @us_citizen.nil?
          "Citizenship status is required"
        elsif @us_citizen == false && @eligible_immigration_status.nil?
          "Eligible immigration status is required"
        elsif @us_citizen == true && @naturalized_citizen.nil?
          "Naturalized citizen is required"
        end
        self.errors.add(:base, error_message)
      end

      def application
        return @application if defined? @application
        @application = FinancialAssistance::Application.find(application_id) if application_id.present?
      end

      def applicant
        return @applicant if defined? @applicant
        @applicant = @application.applicants.find(applicant_id) if applicant_id.present?
      end

      def save
        applicant_entity = FinancialAssistance::Operations::Applicant::Create.new.call(params: extract_applicant_params)

        if applicant_entity.success?
          values = applicant_entity.success.to_h.except(:addresses, :emails, :phones).merge(nested_parameters)
          applicant = application.applicants.find(applicant_id) if applicant_id.present?

          if applicant.present? && applicant.persisted?
            applicant.update(values)
          else
            applicant = application.applicants.build(values)
            applicant.save
          end

          application.ensure_relationship_with_primary(applicant, relationship)
          [true, applicant]
        else
          [false, applicant_entity.failure.errors.to_h]
        end
      end

      def extract_applicant_params
        assign_citizen_status

        attrs = {
          first_name: first_name,
          last_name: last_name,
          middle_name: middle_name,
          gender: gender,
          dob: dob,
          ssn: ssn,
          no_ssn: no_ssn,
          is_consumer_role: is_consumer_role,
          is_homeless: is_homeless,
          is_incarcerated: is_incarcerated,
          same_with_primary: same_with_primary,
          is_applying_coverage: is_applying_coverage,
          ethnicity: ethnicity.to_a.reject(&:blank?),
          indian_tribe_member: indian_tribe_member,
          tribal_id: tribal_id,
          citizen_status: citizen_status,
          is_temporarily_out_of_state: is_temporarily_out_of_state
        }.reject{|k, val| val.nil?}

        attrs.merge({
          adddresses: nested_parameters[:addresses_attributes],
          phones: nested_parameters[:phones_attributes],
          emails: nested_parameters[:emails_attributes]
        })
      end

      def nested_parameters
        {
          addresses_attributes: addresses_attributes.reject{|key, value| value[:address_1].blank? && value[:city].blank? && value[:state].blank? && value[:zip].blank?},
          phones_attributes: phones_attributes.reject{|key, value| value[:full_phone_number].blank?},
          emails_attributes: emails_attributes.reject{|key, value| value[:address].blank?}
        }
      end
    end
  end
end
