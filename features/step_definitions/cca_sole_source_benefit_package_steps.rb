require File.join(File.dirname(__FILE__), "..", "..", "components/benefit_sponsors/spec/support/benefit_sponsors_site_spec_helpers")
require File.join(File.dirname(__FILE__), "..", "..", "components/benefit_sponsors/spec/support/benefit_sponsors_product_spec_helpers")

def products_for(product_package, calender_year)
  puts "Found #{BenefitMarkets::Products::HealthProducts::HealthProduct.by_product_package(product_package).count} products for #{calender_year} #{product_package.package_kind.to_s}"
  BenefitMarkets::Products::HealthProducts::HealthProduct.by_product_package(product_package).collect { |prod| prod.create_copy_for_embedding }
end

def effective_date(start_or_end)
  effective_year = Time.now.year
  return Date.new(effective_year, 1, 1) if start_or_end == "start"
  return Date.new(effective_year, 12, 31) if start_or_end == "end"
end

Given (/^.*a configured CCA benefit market, pricing models, and catalog$/) do
  @site = ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market(:aca_shop)
  benefit_market = @site.benefit_markets.first
  ::BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_catalog(
    @site,
    benefit_market,
    (effective_date("start")..effective_date("end"))
  )
end

Given (/^.*a CCA sole source employer health benefit package, in open enrollment$/) do
  primary_office_location = ::BenefitSponsors::Locations::OfficeLocation.new({
    :address => ::BenefitSponsors::Locations::Address.new(
      {
        address_1: "27 Reo Road",
        state: "MA",
        zip: "01754",
        county: "Middlesex",
        city: "Maynard",
        kind: "work"
      }
    ),
    :phone => BenefitSponsors::Locations::Phone.new({:area_code => "555", :number => "5555555", :kind => "work"}),
    is_primary: true
  })
  e_profile = ::BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new({
    :sic_code => "2035",
    :contact_method => :paper_and_electronic,
    :office_locations => [primary_office_location]
  })
  @employer_organization = ::BenefitSponsors::Organizations::GeneralOrganization.create!({
    :legal_name => "Generic Employer",
    :fein => "123423444",
    :entity_kind => "c_corporation",
    :profiles => [e_profile],
    :site => @site
  })
  @employer_profile = @employer_organization.profiles.first
  @benefit_sponsorship = @employer_profile.add_benefit_sponsorship
  @benefit_sponsorship.save!
  benefit_application = ::BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(
    @benefit_sponsorship,
    effective_period: (effective_date("start")..effective_date("end")),
    open_enrollment_period: (Date.new(2018,7,1)..Date.new(2018,7,20)),
    fte_count: 5,
    pte_count: 0,
    msp_count: 0
  )
  benefit_application.benefit_sponsor_catalog = @benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.effective_period.begin)
  benefit_application.save!
  benefit_application.benefit_sponsor_catalog.save!
  @benefit_application = benefit_application
  p_package = @benefit_application.benefit_sponsor_catalog.product_packages.detect { |p_package| (p_package.package_kind == :single_product) && (p_package.product_kind == :health) }
  @reference_product = p_package.products.first
  factory = BenefitSponsors::BenefitPackages::BenefitPackageFactory
  benefit_package_attributes = {
    title: "My Sole-Source Package",
    probation_period_kind: :first_of_month,
    sponsored_benefits_attributes: [{
      kind: :health,
      product_package_kind: :single_product,
      reference_product: @reference_product,
      sponsor_contribution_attributes: {
        contribution_levels_attributes: []
      }
    }]
  }
  @benefit_package = factory.call(benefit_application, benefit_package_attributes)
  cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
  sb = @benefit_package.sponsored_benefits.first
  sbenefit, _price, _cont = cost_estimator.calculate(sb, sb.reference_product, sb.product_package, build_new_pricing_determination: true)
  @benefit_package.save!
  @benefit_sponsorship.update_attributes!({aasm_state: :applicant})
  @benefit_application.update_attributes!({aasm_state: :enrollment_open})
end

Given (/^.*an employee eligible for shopping during open enrollment, who is linked$/) do
  @census_employee = ::CensusEmployee.new({
    :benefit_sponsors_employer_profile_id => @employer_profile.id,
    :dob => Date.new(1970, 3, 4),
    :ssn => "111111115",
    :first_name => "Employee",
    :last_name => "One",
    :gender => "male",
    :hired_on => Date.new(2014, 6, 15),
    :benefit_sponsorship_id => @benefit_sponsorship.id
  })
  @census_employee.save!
  sqs = [0,1,2].map do |num|
    SecurityQuestion.create!(
      :title => "Question ##{num}"
    )
  end
  sqs = SecurityQuestion.all.to_a
  sq_responses = [0,1,2].map do |num|
    SecurityQuestionResponse.new(
      :security_question_id => sqs[num].id,
      :question_answer => "a"
    )
  end
  @user = User.create!(
    :email => "employee1@place.com",
    :oim_id => "employee1@place.com",
    :password => "aA1!aA1!aA1!",
    :password_confirmation => "aA1!aA1!aA1!",
    :security_question_responses => sq_responses
  )
  @person = Person.new(
    ssn: "111111115",
    first_name: "Employee",
    last_name: "One",
    gender: "male",
    dob: Date.new(1970, 3, 4)
  )
  Factories::EnrollmentFactory.construct_employee_role(
    @user,
    @census_employee,
    @person
  )
  BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache!
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(@benefit_application.benefit_sponsorship, @benefit_application.effective_period.min)
  sb = @benefit_package.sponsored_benefits.first
  sbc, _price, _cont = cost_estimator.calculate(sb, sb.reference_product, sb.product_package)
  sbc.save!
end

Given (/^.*eligible, linked employee is logged in$/) do
  login_as(@user)
end

Given (/^.*made a group selection during open enrollment$/) do
  person = @user.person
  params = ActionController::Parameters.new({
    'person_id' => @user.person.id, 'coverage_kind' => 'health'
  })
  adapter = GroupSelectionPrevaricationAdapter.initialize_for_common_vars(params)
  builder = ::EnrollmentShopping::EnrollmentBuilder.new(
    adapter.coverage_household,
    @user.person.employee_roles.first,
    adapter.coverage_kind
  )
  family_member_ids = [person.primary_family.primary_applicant.id]
  enrollment = builder.build_common_enrollment_information("employer_sponsored")
  enrollment.effective_on = Date.new(2018,8,1)
  enrollment.enrollment_kind = "open_enrollment"
  sponsored_benefit = @benefit_package.sponsored_benefit_for(adapter.coverage_kind)
  builder.build_enrollment_members(enrollment, family_member_ids)
  builder.set_benefit_information(enrollment, sponsored_benefit, @benefit_package)
  enrollment.save!
  @enrollment = enrollment
end

When (/^.*visit the group selection page during open enrollment$/) do
 visit new_insured_group_selection_path(person_id: @user.person.id, coverage_kind: 'health')
end

When (/^.*visit the plan shopping page$/) do
  visit insured_plan_shopping_path(id: @enrollment.id)
end

Then (/^.*see a selectable list of family members for my group$/) do
  expect(page).to have_text("Employee One")
end

Then (/^.*see a selectable 'health' benefit option$/) do
  expect(page).to have_selector("input[type='radio'][value='health'][name='coverage_kind']", visible: false)
end

Then (/^.*see my sole source plan$/) do
  expect(page).to have_text(@reference_product.title)
end

Then (/^.* see the waive coverage button$/) do
  expect(page).to have_selector("a.btn", text: "Waive Coverage")
end
