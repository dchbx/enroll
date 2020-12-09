# frozen_string_literal: true

module Validators
  class StaffContract < Dry::Validation::Contract

    params do
      required(:person_id).value(:string)
      required(:first_name).value(:string)
      required(:last_name).value(:string)
      optional(:profile_id).value(:string)
      optional(:gender).maybe(:string)
      optional(:dob).maybe(:date)
      optional(:area_code).maybe(:string)
      optional(:number).maybe(:string)
      optional(:email).maybe(:string)
      required(:coverage_record).schema do
        optional(:ssn).maybe(:string)
        optional(:dob).maybe(:date)
        optional(:hired_on).maybe(:date)
        required(:is_applying_coverage).value(:bool)
      end
    end
  end
end
