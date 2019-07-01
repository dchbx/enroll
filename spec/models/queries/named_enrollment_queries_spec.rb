require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe Queries::NamedEnrollmentQueries, "Enrollment Queries", dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"
  include_context "setup employees with benefits"

  describe "Shope enrollments" do
    let!(:effective_on) {effective_period.min}
    let!(:organization) {abc_organization}
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let!(:current_effective_date) { Date.new(TimeKeeper.date_of_record.last_year.year, TimeKeeper.date_of_record.month, 1) }
    let!(:save_catalog){ benefit_market.benefit_market_catalogs.map(&:save)}
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product)}
    let(:active_household) {family.active_household}
    let(:sponsored_benefit) {current_benefit_package.sponsored_benefits.first}
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
    let!(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: current_benefit_package.start_on, benefit_group_id:nil, benefit_package: current_benefit_package, is_active:false)}
    let(:reference_product) {current_benefit_package.sponsored_benefits.first.reference_product}
    let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true, coverage_start_on: current_benefit_package.start_on, eligibility_date: current_benefit_package.start_on, applicant_id: family.family_members.first.id) }
    let(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, hbx_enrollment_members:[hbx_enrollment_member],product: reference_product,sponsored_benefit_id:sponsored_benefit.id, sponsored_benefit_package_id: current_benefit_package.id, effective_on:predecessor_application.effective_period.min, household:family.active_household,benefit_group_assignment_id: benefit_group_assignment.id, employee_role_id:employee_role.id, benefit_sponsorship_id:benefit_sponsorship.id, submitted_at:Date.new(2018,6,21))}
    let!(:person) {FactoryBot.create(:person, first_name: ce.first_name, last_name: ce.last_name, ssn:ce.ssn)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person:person)}
    let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
    let!(:ce)  { census_employees[0]}
    let(:subject) {::Queries::NamedEnrollmentQueries.new}

    before(:each) do
      person = family.primary_applicant.person
      person.employee_roles = [employee_role]
      person.employee_roles.map(&:save)
      active_household.hbx_enrollments =[enrollment]
      active_household.save!
    end

    it '.shop_initial_enrollments' do 
      ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_profile(abc_organization.employer_profile).first.benefit_applications.first.update_attributes(aasm_state:"binder_paid",effective_period:predecessor_application.effective_period)
      query =  ::Queries::NamedEnrollmentQueries.shop_initial_enrollments(abc_organization,predecessor_application.effective_period.min)
      expect(query.map{|er|er}).to include (enrollment.hbx_id)
    end
    
    it '.find_simulated_renewal_enrollments' do 
      ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_profile(abc_organization.employer_profile).first.benefit_applications.first.update_attributes(aasm_state:"binder_paid",effective_period:predecessor_application.effective_period)
      query =  ::Queries::NamedEnrollmentQueries.find_simulated_renewal_enrollments(current_benefit_package.sponsored_benefits, predecessor_application.effective_period.min, as_of_time = ::TimeKeeper.date_of_record)
      expect(query.map{|er|er}).to include (enrollment.hbx_id)
    end
  end

  describe "given a renewing employer who has completed their open enrollment" do

    let(:renewal_state) { :enrollment_eligible }
    let(:open_enrollment_period)   { (effective_period.min.prev_month - 2.days)..(effective_period.min - 10.days) }
    let!(:effective_on) {effective_period.min}
    let!(:organization) {abc_organization}
    let!(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: current_benefit_package.start_on, benefit_group_id:nil, benefit_package: current_benefit_package, is_active:false)}
    let(:reference_product) {current_benefit_package.sponsored_benefits.first.reference_product}
    let!(:ce)  { census_employees[0]}
    let!(:person) {FactoryBot.create(:person, first_name: ce.first_name, last_name: ce.last_name, ssn:ce.ssn)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person:person)}
    let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
    let!(:initial_enrollment) { 
      hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                          household: family.active_household, 
                          aasm_state: "coverage_enrolled",
                          family: family,
                          rating_area_id: predecessor_application.recorded_rating_area_id,
                          sponsored_benefit_id: predecessor_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: predecessor_application.benefit_packages.first.id,
                          benefit_sponsorship_id: predecessor_application.benefit_sponsorship.id,
                          employee_role_id: employee_role.id,
                          submitted_at:Date.new(2018,6,21)
                          ) 
      hbx_enrollment.benefit_sponsorship = benefit_sponsorship
      hbx_enrollment.save!
      hbx_enrollment
    }

    let!(:renewal_enrollment) { 
      hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                          household: family.active_household, 
                          family: family,
                          aasm_state: "coverage_selected",
                          rating_area_id: renewal_application.recorded_rating_area_id,
                          sponsored_benefit_id: renewal_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: renewal_application.benefit_packages.first.id,
                          benefit_sponsorship_id: renewal_application.benefit_sponsorship.id,
                          employee_role_id: employee_role.id
                          ) 
      hbx_enrollment.benefit_sponsorship = benefit_sponsorship
      hbx_enrollment.save!
      hbx_enrollment
    }

    let(:subject) {::Queries::NamedEnrollmentQueries}

    before do
      ce.update_attributes(:employee_role_id => employee_role.id )
    end

    it '.renewal_gate_lifted_enrollments' do 
      value = subject.renewal_gate_lifted_enrollments(organization, effective_on, as_of_time = ::TimeKeeper.date_of_record)
      expect(value.map{|er|er}).to include (renewal_enrollment.hbx_id)
    end
  end
end