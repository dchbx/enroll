module BenefitSponsors
  class Members::Member
    include Mongoid::Document
    include Mongoid::Timestamps

    GENDER_KINDS          = [:male, :female]
    KINSHIP_MAP           = {
        :self                       => :self,
        :spouse                     => :spouse,
        :domestic_partner           => :domestic_partner,
        :child_under_26             => :child,
        :disabled_child_26_and_over => :disabled_child,
      }

    field :hbx_id,              type: String
    field :sponsor_assigned_id, type: String

    field :first_name,          type: String
    field :middle_name,         type: String
    field :last_name,           type: String
    field :name_sfx,            type: String
    field :kinship_to_primary_member,  type: Symbol

    field :encrypted_ssn,       type: String
    field :gender,              type: Symbol
    field :dob,                 type: Date


    embeds_one  :address, 
                class_name: "BenefitSponsors::Locations::Address"
    embeds_one  :email, 
                class_name: "::Email"

    accepts_nested_attributes_for :address, 
                                  reject_if: :all_blank, 
                                  allow_destroy: true

    accepts_nested_attributes_for :email, 
                                  allow_destroy: true

    validate :birth_date_range

    validates :gender,
      allow_blank: true,
      allow_nil: true,
      inclusion: { in: GENDER_KINDS, message: "'%{value}' is not a valid gender kind" }

    validates :kinship_to_primary_member,
      presence: true,
      allow_blank: true,
      allow_nil:   true,
      inclusion: {
        in: KINSHIP_MAP.keys,
        message: "'%{value}' is not a valid relationship kind"
      }

    def ssn=(new_ssn)
      if new_ssn.present?
        ssn_val = new_ssn.to_s.gsub(/\D/, '')
        if is_ssn_valid?(ssn_val)
          encrypted_ssn = encrypt(ssn_val) 
        else
          nil
        end
      end
    end

    def ssn
      decrypt(encrypted_ssn) if encrypted_ssn.present?
    end

    def age_on(date = TimeKeeper.date_of_record)
      return unless dob.present?
      date.year - dob.year - ((date.month > dob.month || (date.month == dob.month && date.day >= dob.day)) ? 0 : 1)
    end

    def full_name
      case name_sfx
      when "ii" ||"iii" || "iv" || "v"
        [first_name.capitalize, last_name.capitalize, name_sfx.upcase].compact.join(" ")
      else
        [first_name.capitalize, last_name.capitalize, name_sfx].compact.join(" ")
      end
    end

    def gender=(new_gender)
      if new_gender.present?
        super(new_gender.to_s.downcase)
      else
        super(nil)
      end
    end

    def dob=(new_dob)
      if new_dob.is_a?(Date) || new_dob.is_a?(Time)
        super(new_dob)
      elsif new_dob.is_a?(String)
        transform_date = Date.strptime(new_dob, "%Y-%m-%d").to_date rescue nil
        super(transform_date)
      else
        super(nil)
      end
    end

    def is_primary_member?
      class_name_starts_with?(["employee", "survivor", "family"])
    end

    def is_dependent_member?
      class_name_starts_with?(["dependent"])
    end

    def is_survivor_member?
      class_name_starts_with?(["survivor"])
    end

    def is_spouse_relationship?
      return unless kinship_to_primary_member.present?
      [:spouse, :domestic_partner].include?(kinship_to_primary_member)
    end

    def is_child_relationship?
      return unless kinship_to_primary_member.present?
      [:child_under_26, :disabled_child_26_and_over].include?(kinship_to_primary_member)
    end


    private

    def is_ssn_valid?(ssn)
      return false unless ssn.present?

      # Invalid compositions:
      #   All zeros or 000, 666, 900-999 in the area numbers (first three digits);
      #   00 in the group number (fourth and fifth digit); or
      #   0000 in the serial number (last four digits)

      if ssn.present?
        invalid_area_numbers = %w(000 666)
        invalid_area_range = 900..999
        invalid_group_numbers = %w(00)
        invalid_serial_numbers = %w(0000)

        return false if ssn.to_s.blank?
        return false if invalid_area_numbers.include?(ssn.to_s[0,3])
        return false if invalid_area_range.include?(ssn.to_s[0,3].to_i)
        return false if invalid_group_numbers.include?(ssn.to_s[3,2])
        return false if invalid_serial_numbers.include?(ssn.to_s[5,4])
      end

      true    
    end

    def encrypt(value)
      # ::SymmetricEncryption.encrypt(value)
      value
    end

    def decrypt(value)
      # ::SymmetricEncryption.decrypt(value)
      value
    end

    # Case-insensitve match between start of this class name and compare_array
    def class_name_starts_with?(compare_array)
      compare_array.any? { |str| self.class.to_s.demodulize.downcase.start_with?(str) }
    end

    def birth_date_range
      return unless dob.present?

      if dob > TimeKeeper.date_of_record
        errors.add(:dob, message: "future date: #{dob} is not valid for date of birth")
      end
      if (TimeKeeper.date_of_record.year - dob.year) > 110
        errors.add(:dob, message: "date of birth cannot be more than 110 years ago")
      end
    end


  end
end
