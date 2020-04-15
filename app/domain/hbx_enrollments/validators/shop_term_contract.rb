# frozen_string_literal: true

module HbxEnrollments
  module Validators
    class ShopTermContract < ShopContract
      params do
        required(:terminated_on).filled(type?: Date)
        required(:termination_submitted_on).filled(type?: Date)
      end
    end
  end
end