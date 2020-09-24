# frozen_string_literal: true

module FinancialAssistance
  module Forms
    class Applicant
      include ActiveModel::Model
      include ActiveModel::Validations
      include Config::AcaModelConcern

      attr_accessor :id, :family_id, :is_consumer_role, :is_resident_role, :vlp_document_id
      attr_accessor :application_id, :applicant_id
      attr_accessor :gender, :relationship, :relation_with_primary
      attr_accessor :no_dc_address, :is_homeless, :is_temporarily_out_of_state, :same_with_primary, :is_applying_coverage
      attr_accessor :addresses, :phones, :emails
      attr_accessor :addresses_attributes, :phones_attributes, :emails_attributes

      attr_writer :family

      include FinancialAssistance::Forms::PeopleNames
      include FinancialAssistance::Forms::ConsumerFields
      include FinancialAssistance::Forms::SsnField
      include FinancialAssistance::Forms::DateOfBirthField

      RELATIONSHIPS = FinancialAssistance::Relationship::RELATIONSHIPS + ::BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS

      validates_presence_of :first_name, :allow_blank => nil
      validates_presence_of :last_name, :allow_blank => nil
      validates_presence_of :gender, :allow_blank => nil
      validates_presence_of :dob
      # validates_inclusion_of :relationship, :in => RELATIONSHIPS.uniq, :allow_blank => nil, message: ""
      validate :relationship_validation
      validate :consumer_fields_validation

      attr_reader :dob

      def initialize(*attributes)
        initialize_attributes
        super
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
        self.errors.add(:base, error_message) if error_message.present?
      end

      def persisted?
        return false unless applicant
        applicant.persisted?
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
        return false unless valid?
        applicant_entity = FinancialAssistance::Operations::Applicant::Build.new.call(params: extract_applicant_params)
        if applicant_entity.success?
          values = applicant_entity.success.to_h.except(:addresses, :emails, :phones).merge(nested_parameters)
          applicant = application.applicants.find(applicant_id) if applicant_id.present?

          if applicant.present? && applicant.persisted?
            applicant.update(values)
          else
            applicant = application.applicants.build(values)
            applicant.save!
          end
          application.ensure_relationship_with_primary(applicant, relationship) if relationship.present?
          [true, applicant]
        else
          applicant_entity.failure.errors.to_h.collect{|key, msg| "#{key} #{msg[0]}"}.each do |error_msg|
            errors.add(:base, error_msg)
          end
          [false, applicant_entity.failure]
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
        }#.reject{|_k, val| val.nil?}

        if same_with_primary == 'true'
          primary = application.primary_applicant
          attrs.merge!(no_dc_address: primary.no_dc_address, is_homeless: primary.is_homeless?, is_temporarily_out_of_state: primary.is_temporarily_out_of_state?)
        end

        attrs.merge!(vlp_parameters)
        attrs.merge({
                      addresses: nested_parameters[:addresses_attributes].values,
                      phones: nested_parameters[:phones_attributes]&.values || [],
                      emails: nested_parameters[:emails_attributes]&.values || []
                    })
      end


      def vlp_parameters
        [:vlp_subject, :alien_number, :i94_number, :visa_number, :passport_number, :sevis_id,
         :naturalization_number, :receipt_number, :citizenship_number, :card_number,
         :country_of_citizenship, :expiration_date, :issuing_country, :status, :vlp_description].inject({}) do |attrs, attribute|
          attrs[attribute] = self.send(attribute) if self.send(attribute).present?
          attrs
        end
      end

      def nested_parameters
        address_params = addresses_attributes.reject{|_key, value| value[:address_1].blank? && value[:city].blank? && value[:state].blank? && value[:zip].blank?}
        address_params = primary_applicant_address_attributes if address_params.blank? && same_with_primary == 'true'

        params = {addresses_attributes: address_params}
        params.merge(phones_attributes: phones_attributes.reject{|_key, value| value[:full_phone_number].blank?}) if phones_attributes.present?
        params.merge(emails_attributes: emails_attributes.reject{|_key, value| value[:address].blank?}) if emails_attributes.present?
        params
      end

      def primary_applicant_address_attributes
        primary = application.primary_applicant
        if (home_address = primary.addresses.in(kind: 'home').first)
          address_params = {
            0 => home_address.attributes.slice('address_1', 'address_2', 'address_3', 'county', 'country_name', 'kind', 'city', 'state', 'zip')
          }
        end

        address_params || {}
      end

      def age_on(date)
        age = date.year - dob.year
        if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
          age - 1
        else
          age
        end
      end

      def relationship_validation
        return if relationship.blank?
        primary_relations = application.primary_applicant.relationships.pluck(:kind)

        self.errors.add(:base, "can not have multiple spouse or life partner") if ['spouse', 'life_partner'].include?(relationship) && primary_relations.any?{|relation| ['spouse', 'life_partner'].include?(relation)}
      end
    end
  end
end
