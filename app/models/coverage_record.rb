# frozen_string_literal: true

class CoverageRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_staff_role

  field :encrypted_ssn, type: String
  field :dob, type: Date
  field :hired_on, type: Date
  field :is_applying_coverage, type: Boolean, default: false
end
