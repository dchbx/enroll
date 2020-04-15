# frozen_string_literal: true

module HbxEnrollments
  module Validators
    class ShopContract < EnrollmentContract
      params do
        required(:employee_role_id).filled(type?: BSON::ObjectId)
        optional(:benefit_group_id).maybe(type?: BSON::ObjectId)
        required(:benefit_group_assignment_id).filled(type?: BSON::ObjectId)
        required(:benefit_sponsorship_id).filled(type?: BSON::ObjectId)
        required(:sponsored_benefit_package_id).filled(type?: BSON::ObjectId)
        required(:sponsored_benefit_id).filled(type?: BSON::ObjectId)
        required(:rating_area_id).filled(type?: BSON::ObjectId)
      end
    end
  end
end