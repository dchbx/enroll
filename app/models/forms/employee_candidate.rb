module Forms
  class EmployeeCandidate
    include ActiveModel::Model
    include ActiveModel::Validations

    include PeopleNames
    include SsnField
    attr_accessor :gender

    attr_accessor :user_id
    attr_accessor :dob_check

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :dob
    # include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)

    validate :does_not_match_a_different_users_person
    validates :ssn,
              length: {minimum: 9, maximum: 9, message: "SSN must be 9 digits"},
              numericality: true
    validate :dob_not_in_future

    attr_reader :dob

    def dob=(val)
      @dob = val.class == Date ? val : Date.strptime(val, "%Y-%m-%d") rescue nil
    end

    # TODO fix and use as the only way to match census employees for the employee flow or blow this away
    def match_census_employees
      CensusEmployee.matchable(ssn, dob).to_a + CensusEmployee.unclaimed_matchable(ssn, dob).to_a
    end

    def match_person
      if !ssn.blank?
        Person.where({
                       :dob => dob,
                       :encrypted_ssn => Person.encrypt_ssn(ssn)
                   }).first || match_ssn_employer_person
      else
        Person.where({
                       :dob => dob,
                       :last_name => /^#{last_name}$/i,
                       :first_name => /^#{first_name}$/i,
                   }).first
      end
    end

    def match_ssn_employer_person
      potential_person = Person.where({
                       :dob => dob,
                       :last_name => /^#{last_name}$/i,
                       :first_name => /^#{first_name}$/i,
                   }).first
      return potential_person if potential_person.present? && potential_person.employer_staff_roles?
      nil
    end

    def does_not_match_a_different_users_person
      matched_person = match_person
      if matched_person.present?
        if matched_person.user.present?
          if matched_person.user.id.to_s != self.user_id.to_s
            errors.add(
                :base,
                "#{first_name} #{last_name} is already affiliated with another account"
            )
          end
        end
      end
      true
    end

    def dob_not_in_future
      if self.dob && self.dob > ::TimeKeeper.date_of_record
        errors.add(
            :dob,
            "#{dob} can't be in the future.")
        self.dob=""
      end
    end

    def persisted?
      false
    end
  end
end
