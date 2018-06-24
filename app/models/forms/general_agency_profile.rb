module Forms
  class GeneralAgencyProfile < ::Forms::OrganizationSignup
    include ActiveModel::Validations
    include Validations::Email

    attr_accessor :general_agency_profile, :applicant_type, :general_agency_profile_id
    attr_accessor :market_kind, :languages_spoken, :email
    attr_accessor :working_hours, :accept_new_clients, :home_page
    include NpnField

    validates :market_kind,
              inclusion: {in: ::GeneralAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid market kind"},
              allow_blank: false

    validates :email, :email => true, :allow_blank => false

    validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, message: "%{value} is not valid"
    validate :validate_duplicate_npn

    class OrganizationAlreadyMatched < StandardError;
    end

    def self.model_name
      ::GeneralAgencyProfile.model_name
    end

    def add_staff_role
      person.general_agency_staff_roles << ::GeneralAgencyStaffRole.new({:npn => self.npn})
    end

    def save(current_user=nil)
      begin
        if only_staff_role?
          general_agency_profile = ::GeneralAgencyProfile.find(self.general_agency_profile_id)
        else
          return false unless valid?
          check_existing_organization
        end
        match_or_create_person
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue OrganizationAlreadyMatched
        errors.add(:base, "organization has already been created.")
        return false
      rescue BSON::ObjectId::Invalid
        errors.add(:base, "General agency can not be blank.")
        return false
      rescue => e
        return false
      end

      person.save!
      add_staff_role
      if only_staff_role?
        person.general_agency_staff_roles.last.update_attributes({general_agency_profile_id: general_agency_profile.id})
      else
        organization = create_or_find_organization
        self.general_agency_profile = organization.general_agency_profile
        self.general_agency_profile.save!
        person.general_agency_staff_roles.last.update_attributes({general_agency_profile_id: self.general_agency_profile.id})
      end
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

    def only_staff_role?
      self.applicant_type == 'staff'
    end

    def create_or_find_organization
      existing_org = Organization.where(:fein => self.fein)
      if existing_org.present? && !existing_org.first.general_agency_profile.present?
        new_general_agency_profile = ::GeneralAgencyProfile.new({
                                                                    :entity_kind => entity_kind,
                                                                    :home_page => home_page,
                                                                    :market_kind => market_kind,
                                                                    :languages_spoken => languages_spoken,
                                                                    :working_hours => working_hours,
                                                                    :accept_new_clients => accept_new_clients})
        existing_org = existing_org.first
        existing_org.update_attributes!(general_agency_profile: new_general_agency_profile)
        existing_org
      else
        Organization.create!(
            :fein => fein,
            :legal_name => legal_name,
            :dba => dba,
            :general_agency_profile => ::GeneralAgencyProfile.new({
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

    def self.find(general_agency_profile_id)
      general_agency_profile = ::GeneralAgencyProfile.find(general_agency_profile_id)
      organization = general_agency_profile.organization
      general_agency_role = general_agency_profile.primary_staff
      person = general_agency_role.try(:person)
      attributes = {
          id: organization.id,
          legal_name: organization.legal_name,
          dba: organization.dba,
          fein: organization.fein,
          home_page: organization.home_page,
          npn: general_agency_role.npn,
          entity_kind: general_agency_profile.entity_kind,
          market_kind: general_agency_profile.market_kind,
          languages_spoken: general_agency_profile.languages_spoken,
          working_hours: general_agency_profile.working_hours,
          accept_new_clients: general_agency_profile.accept_new_clients,
          office_locations: organization.office_locations
      }
      if person.present?
        attributes.merge!({
                              first_name: person.first_name,
                              last_name: person.last_name,
                              dob: person.dob.try(:strftime, '%Y-%m-%d'),
                              email: person.emails.first.address,
                          })
      end
      record = self.new(attributes)
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
      organization.general_agency_profile.update_attributes(extract_general_agency_profile_params)
        #if person.present?
        #  person.update_attributes(extract_person_params)
        #  person.emails.find_by(kind: 'work').update(address: attr[:email])
        #end
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

    def extract_general_agency_profile_params
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
      if Person.where("general_agency_staff_roles.npn" => npn).any?
        errors.add(:base, "NPN has already been claimed by another general agency staff. Please contact HBX-Customer Service - Call (855) 532-5465.")
      end
    end

    def check_existing_organization
      existing_org = Organization.where(:fein => self.fein)
      if existing_org.present? && existing_org.first.general_agency_profile.present?
        raise OrganizationAlreadyMatched.new
      end
    end
  end
end
