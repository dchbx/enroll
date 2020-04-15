# frozen_string_literal: true

module HbxEnrollments
  module Validators
    class EndDateChangeContract < Dry::Validation::Contract
      params do
        required(:enrollment_id).filled(:string)
        required(:new_term_date).filled(:date)
        required(:edi_required).filled(:bool)
      end
    end
  end
end