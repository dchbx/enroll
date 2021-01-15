# frozen_string_literal: true

#benefit_sponsors/benefit_sponsorships/5ff77ba896a4a17b76f892bb/benefit_applications/5ff8aefe96a4a17b7bf89317/benefit_packages/new
class EmployerBenefitPackageSetUp

  def self.my_benefit_package
    'benefit_package[title]'
  end

  def self.my_description
    'benefit_package[description]'
  end

  def self.first_of_the_month_dropdown
    'div[class="row row-form-wrapper"] span'
  end

  def self.by_carrier_btn
    'a[class="interaction-click-control-by-carrier"]'
  end

  def self.by_metal_level_btn
    'a[class="interaction-click-control-by-metal-level"]'
  end

  def self.single_plan_btn
    'a[class="interaction-click-control-single-plan"]'
  end
end