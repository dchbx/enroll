module Forms
  class ConsumerCandidate
    include Acapi::Notifiers
    include ActiveModel::Model
    include ActiveModel::Validations

    include PeopleNames
    include SsnField
    attr_accessor :gender
    attr_accessor :user_id
    attr_accessor :no_ssn
    attr_accessor :dob_check #hidden input filed for one time DOB warning

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :dob
    # include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)

    validate :does_not_match_a_different_users_person
    validates :ssn,
              length: {minimum: 9, maximum: 9, message: " must be 9 digits"},
              allow_blank: true,
              numericality: true
    validate :dob_not_in_future
    validate :ssn_or_checkbox
    validate :uniq_ssn, :uniq_ssn_dob
    validate :age_less_than_18
    attr_reader :dob

    def ssn_or_checkbox
      if ssn.blank? && no_ssn == "0"
        errors.add(:base, 'Check No SSN box or enter a valid SSN')
      end
    end

    def dob=(val)
      @dob = Date.strptime(val, "%Y-%m-%d") rescue nil
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

    def uniq_ssn
      return true if ssn.blank?
      same_ssn = Person.where(encrypted_ssn: Person.encrypt_ssn(ssn))
      if same_ssn.present? && same_ssn.first.try(:user)
        errors.add(:ssn_taken,
                  #{}"This Social Security Number has been taken on another account.  If this is your correct SSN, and you don’t already have an account, please contact #{HbxProfile::CallCenterName} at #{HbxProfile::CallCenterPhoneNumber}.")
                  "The social security number you entered is affiliated with another account.")
      end
    end

    def uniq_ssn_dob
      return true if ssn.blank?
      person_with_ssn = Person.where(encrypted_ssn: Person.encrypt_ssn(ssn)).first
      person_with_ssn_dob = Person.where(encrypted_ssn: Person.encrypt_ssn(ssn), dob: dob).first
      if person_with_ssn != person_with_ssn_dob
        errors.add(:base,
          "This Social Security Number and Date-of-Birth is invalid in our records.  Please verify the entry, and if correct, contact the DC Customer help center at #{Settings.contact_center.phone_number}.")
        log("ERROR: unable to match or create Person record, SSN exists with different DOB", {:severity => "error"})
      end
    end

    def does_not_match_a_different_users_person
      matched_person = match_person
      if matched_person.present?
        if matched_person.user.present?
          if matched_person.user.id.to_s != self.user_id.to_s
            errors.add(
                :base,
                "#{first_name} #{last_name} is already affiliated with another account."
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

    # Throw Error/Warning if user age is less than 18
    def age_less_than_18
      if self.dob_check == "false" || self.dob_check.blank?
        if ::TimeKeeper.date_of_record.year - self.dob.year < 18
          errors.add(:base, "Please verify your date of birth. If it's correct, please continue.")
          self.dob_check = true
        else
          self.dob_check = false
        end
      end
    end

    def persisted?
      false
    end
  end
end
