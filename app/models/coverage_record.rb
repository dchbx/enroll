# frozen_string_literal: true

class CoverageRecord
  include Mongoid::Document
  include Mongoid::Timestamps
  include Ssn

  embedded_in :employer_staff_role

  field :encrypted_ssn, type: String
  field :dob, type: Date
  field :hired_on, type: Date
  field :gender, type: String
  field :is_applying_coverage, type: Boolean, default: false

  def ssn=(val)
    return if val.blank?

    ssn_val = val.to_s.gsub(/\D/, '')
    self.encrypted_ssn = SymmetricEncryption.encrypt(ssn_val)
  end
end