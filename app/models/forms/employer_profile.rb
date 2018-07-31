require 'date'
module Forms
  class EmployerProfile  < ::Forms::OrganizationSignup
    attr_reader :employer_profile
    attr_accessor :email
    attr_accessor :area_code
    attr_accessor :number
    attr_accessor :extension
    class OrganizationAlreadyMatched < StandardError; end

    def check_existing_organization
      claimed = false
      existing_org = Organization.where(:fein => fein).first
      if existing_org.present?
        if existing_org.employer_profile.present?
          if (Person.where({"employer_staff_roles.employer_profile_id" => existing_org.employer_profile._id}).any?)
            claimed = true
          end
        end
      end
      [existing_org, claimed]
    end

    def create_employer_staff_role(current_user, employer_profile, existing_company)
      person.user = current_user
      employer_ids = person.employer_staff_roles.map(&:employer_profile_id)
      if employer_ids.include? employer_profile.id
        pending = false
      else
        pending = existing_company && Person.staff_for_employer(employer_profile).detect{|person|person.user_id}
        role_state = pending ? 'is_applicant' : 'is_active'
        person.employer_staff_roles << EmployerStaffRole.new(person: person, :employer_profile_id => employer_profile.id, is_owner: true, aasm_state: role_state)
      end
      current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
      current_user.save!
      person.save!
      pending
    end

    def save(current_user, employer_profile_id)
      return false unless valid?
      begin
        match_or_create_person(current_user)
        person.save!
        person.contact_info(email, area_code, number, extension) if email
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue PersonAlreadyMatched
        errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        return false
      end
      return false if person.errors.present?
      existing_org, claimed = check_existing_organization
      if existing_org
        update_organization(existing_org) unless claimed
        @employer_profile = existing_org.employer_profile
      else
        org = create_new_organization
        org.save!
        @employer_profile = org.employer_profile
      end
      pending = create_employer_staff_role(current_user, @employer_profile, claimed)
      [true, pending]
    end

    def create_new_organization
      Organization.create!(
        :fein => fein,
        :legal_name => legal_name,
        :dba => dba,
        :employer_profile => ::EmployerProfile.new({
          :entity_kind => entity_kind,
          :contact_method => contact_method,
          :sic_code => sic_code,
          :employer_attestation => ::EmployerAttestation.new(),
        }),
        :office_locations => office_locations
      )
    end

    def update_organization(org)
      if !org.employer_profile.present?
        org.create_employer_profile({:entity_kind => entity_kind, :sic_code => sic_code})
        org.save!
      end
    end

  end
end
