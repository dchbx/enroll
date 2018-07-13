require 'active_support/concern'

module BenefitSponsors
  module Concerns::Ssn
    extend ActiveSupport::Concern

    included do
      
      validates :ssn,
        length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
        allow_blank: true,
        numericality: true

      validate :is_ssn_composition_correct?
      after_validation :move_encrypted_ssn_errors
    end

    def move_encrypted_ssn_errors
      deleted_messages = errors.delete(:encrypted_ssn)
      if !deleted_messages.blank?
        deleted_messages.each do |dm|
          errors.add(:ssn, dm)
        end
      end
      true
    end

    def ssn_changed?
      encrypted_ssn_changed?
    end

    # Strip non-numeric chars from ssn
    # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
    def ssn=(new_ssn)
      if !new_ssn.blank?
        write_attribute(:encrypted_ssn, self.class.encrypt_ssn(new_ssn))
      else
        unset_sparse("encrypted_ssn")
      end
    end

    def ssn
      ssn_val = read_attribute(:encrypted_ssn)
      if !ssn_val.blank?
        self.class.decrypt_ssn(ssn_val)
      else
        nil
      end
    end

    def is_ssn_composition_correct?
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

    module ClassMethods
      def encrypt_ssn(val)
        if val.blank?
          return nil
        end
        ssn_val = val.to_s.gsub(/\D/, '')
        SymmetricEncryption.encrypt(ssn_val)
      end

      def decrypt_ssn(val)
        SymmetricEncryption.decrypt(val)
      end

      def find_by_ssn(ssn)
        self.where(encrypted_ssn: encrypt_ssn(ssn)).first
      end
    end
  end
end