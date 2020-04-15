# frozen_string_literal: true

require 'dry-struct'

module HbxEnrollments
  module Entities
    class ShopEnrollment < ::HbxEnrollments::Entities::HbxEnrollment

      attribute :employee_role_id,                                Types::Bson
      attribute :benefit_group_id,                                Types::Bson.optional.meta(omittable: true)
      attribute :benefit_group_assignment_id,                     Types::Bson
      attribute :benefit_sponsorship_id,                          Types::Bson
      attribute :sponsored_benefit_package_id,                    Types::Bson
      attribute :sponsored_benefit_id,                            Types::Bson
      attribute :rating_area_id,                                  Types::Bson
    end
  end
end