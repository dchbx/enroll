# frozen_string_literal: true

class Issuer
  include Mongoid::Document

  embeds_many :benefit_products, cascade_callbacks: true
  embeds_many :benefit_product_portfolios, cascade_callbacks: true

  embeds_many :benefit_service_areas, class_name: "GeographicRatingArea"

  # move to benefit product
  # embeds_one  :benefit_service_period,  class_name: "EnrollmentPeriod"

end
