require 'date'
module Forms
  class BrokerAgencyProfile < ::Forms::OrganizationSignup

    include ActiveModel::Validations
    include Validations::Email

    attr_accessor :broker_agency_profile
    attr_accessor :market_kind, :languages_spoken
    attr_accessor :working_hours, :accept_new_clients, :home_page
    attr_accessor :broker_applicant_type, :email
    include NpnField

    validates :market_kind,
      inclusion: { in: ::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid practice area" },
      allow_blank: false

    validates :email, :email => true, :allow_blank => false

    validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, message: "%{value} is not valid"

    validate :validate_duplicate_npn

    class OrganizationAlreadyMatched < StandardError; end

    def initialize(attrs = {})
      self.fein = Organization.generate_fein
      self.is_fake_fein=true
      super(attrs)
    end

    def self.model_name
      ::BrokerAgencyProfile.model_name
    end

    def add_broker_role
      person.broker_role = ::BrokerRole.new({
        :provider_kind => 'broker',
        :npn => self.npn
      })
    end

    def save(current_user=nil)
      return false unless valid?

      begin
        match_or_create_person
        check_existing_organization
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue OrganizationAlreadyMatched
        errors.add(:base, "organization has already been created.")
        return false
      end

      person.save!
      add_broker_role
      organization = create_or_find_organization
      self.broker_agency_profile = organization.broker_agency_profile
      self.broker_agency_profile.primary_broker_role = person.broker_role
      self.broker_agency_profile.save!
      person.broker_role.update_attributes({ broker_agency_profile_id: broker_agency_profile.id , market_kind:  market_kind })
      UserMailer.broker_application_confirmation(person).deliver_now
      # person.update_attributes({ broker_agency_staff_roles: [::BrokerAgencyStaffRole.new(:broker_agency_profile => broker_agency_profile)]})
      true
    end

    def match_or_create_person
      matched_people = Person.where(
        first_name: regex_for(first_name),
        last_name: regex_for(last_name),
        dob: dob
        )

      if matched_people.count > 1
        raise TooManyMatchingPeople.new
      end

      if matched_people.count == 1
        self.person = matched_people.first
      else
        self.person = Person.new({
          first_name: first_name,
          last_name: last_name,
          dob: dob
          })
      end

      self.person.add_work_email(email)
    end

    def create_or_find_organization
      existing_org = Organization.where(:fein => self.fein)
      if existing_org.present? && !existing_org.first.broker_agency_profile.present?
        new_broker_agency_profile = ::BrokerAgencyProfile.new({
            :entity_kind => entity_kind,
            :home_page => home_page,
            :market_kind => market_kind,
            :languages_spoken => languages_spoken,
            :working_hours => working_hours,
            :accept_new_clients => accept_new_clients})
        existing_org = existing_org.first
        existing_org.update_attributes!(broker_agency_profile: new_broker_agency_profile)
        existing_org
      else
        Organization.create!(
          :fein => fein,
          :legal_name => legal_name,
          :dba => dba,
          :is_fake_fein => is_fake_fein,
          :broker_agency_profile => ::BrokerAgencyProfile.new({
            :entity_kind => entity_kind,
            :home_page => home_page,
            :market_kind => market_kind,
            :languages_spoken => languages_spoken,
            :working_hours => working_hours,
            :accept_new_clients => accept_new_clients
          }),
          :office_locations => office_locations
        )
      end
    end

    def self.find(broker_agency_profile_id)
      broker_agency_profile = ::BrokerAgencyProfile.find(broker_agency_profile_id)
      organization = broker_agency_profile.organization
      broker_role = broker_agency_profile.primary_broker_role
      person = broker_role.try(:person)

      record = self.new({
        id: organization.id,
        legal_name: organization.legal_name,
        dba: organization.dba,
        fein: organization.fein,
        home_page: organization.home_page,
        first_name: person.first_name,
        last_name: person.last_name,
        dob: person.dob.try(:strftime, '%Y-%m-%d'),
        email: person.emails.first.address,
        npn: broker_role.try(:npn),
        entity_kind: broker_agency_profile.entity_kind,
        market_kind: broker_agency_profile.market_kind,
        languages_spoken: broker_agency_profile.languages_spoken,
        working_hours: broker_agency_profile.working_hours,
        accept_new_clients: broker_agency_profile.accept_new_clients,
        office_locations: organization.office_locations
      })
    end

    def assign_attributes(atts)
      atts.each_pair do |k, v|
        self.send("#{k}=".to_sym, v)
      end
    end

    def update_attributes(attr)
      assign_attributes(attr)
      organization = Organization.find(attr[:id])
      organization.update_attributes(extract_organization_params(attr))
      organization.broker_agency_profile.update_attributes(extract_broker_agency_profile_params)
      broker_role = organization.broker_agency_profile.primary_broker_role
      person = broker_role.try(:person)
      if person.present?
        person.update_attributes(extract_person_params)
        person.emails.find_by(kind: 'work').update(address: attr[:email])
      end
    rescue
      return false
    end

    def extract_person_params
      {
        :first_name => first_name,
        :last_name => last_name,
        :dob => dob
      }
    end

    def extract_organization_params(attr)
      {
        :fein => fein,
        :legal_name => legal_name,
        :dba => dba,
        :home_page => home_page,
        :office_locations_attributes => attr[:office_locations_attributes]
      }
    end

    def extract_broker_agency_profile_params
      {
        :entity_kind => entity_kind,
        :home_page => home_page,
        :market_kind => market_kind,
        :languages_spoken => languages_spoken,
        :working_hours => working_hours,
        :accept_new_clients => accept_new_clients
      }
    end

    def validate_duplicate_npn
      if Person.where("broker_role.npn" => npn).any?
        errors.add(:base, "NPN has already been claimed by another broker. Please contact HBX-Customer Service - Call (855) 532-5465.")
      end
    end

    def check_existing_organization
      existing_org = Organization.where(:fein => self.fein)
      if existing_org.present? && existing_org.first.broker_agency_profile.present?
        raise OrganizationAlreadyMatched.new
      end
    end
  end
end
