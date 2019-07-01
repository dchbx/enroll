# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe Factories::EnrollmentRenewalFactory, dbclean: :around_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup renewal application"

    let(:product_kinds)                   { [:health, :dental] }
    let(:dental_sponsored_benefit)        { true }
    let(:renewal_state)                   { :enrollment_open }
    let(:dental_package_kind)             { :multi_product }
    let(:catalog_health_package_kinds)    { [:single_issuer, :metal_level, :single_product] }
    let(:catalog_dental_package_kinds)    { [:multi_product, :single_issuer] }
    let(:renewal_effective_date)          { (TimeKeeper.date_of_record + 45.days).beginning_of_month }
    let(:current_effective_date)          { renewal_effective_date.prev_year }
    let(:predecessor_application_catalog) { true }

    let(:hired_on)        { TimeKeeper.date_of_record - 2.years }
    let(:person)          { FactoryBot.create(:person) }
    let(:shop_family)     { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }
    let(:enrollment_kind) { "open_enrollment" }

    let(:census_employee) do
      census_employee = create(:census_employee, :with_active_assignment,
             benefit_sponsorship: benefit_sponsorship,
             employer_profile: benefit_sponsorship.profile,
             benefit_group: current_benefit_package,
             hired_on: hired_on)
      census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee, is_active: false)
      census_employee
    end

    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: shop_family.latest_household,
                        family: shop_family,
                        coverage_kind: coverage_kind,
                        effective_on: current_effective_date,
                        enrollment_kind: 'open_enrollment',
                        kind: "employer_sponsored",
                        submitted_at: current_effective_date - 20.days,
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: current_benefit_package.id,
                        sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                        employee_role_id: employee_role.id,
                        benefit_group_assignment: census_employee.active_benefit_group_assignment,
                        product_id: current_benefit_package.sponsored_benefits[0].reference_product.id,
                        aasm_state: enrollment_status)
    end

    subject { BenefitSponsors::Factories::EnrollmentRenewalFactory.call(enrollment, benefit_package) }

    context 'Renewal factory invoked with health coverage' do

      let(:enrollment_status) { :coverage_selected }
      let(:coverage_kind)     { :health }

      it 'should generate passive renewal' do
        expect(subject).to be_valid
        expect(subject.coverage_kind.to_sym).to eq coverage_kind
        expect(subject.sponsored_benefit_package).to eq benefit_package
        expect(subject.effective_on).to eq renewal_effective_date
        expect(subject.aasm_state).to eq 'auto_renewing'
        expect(subject.sponsored_benefit).to eq benefit_package.sponsored_benefit_for(coverage_kind)
        expect(subject.product).to eq enrollment.product.renewal_product
      end
    end

    context 'Renewal factory invoked with health waiver' do

      let(:enrollment_status) { :inactive }
      let(:coverage_kind)     { :health }
      let(:renewal_health_sponsored_benefit) { }

      it 'should generate passive waiver' do
        expect(subject).to be_valid
        expect(subject.sponsored_benefit_package).to eq benefit_package
        expect(subject.effective_on).to eq renewal_effective_date
        expect(subject.aasm_state).to eq 'renewing_waived'
        expect(subject.sponsored_benefit).to eq benefit_package.sponsored_benefit_for(coverage_kind)
      end
    end

    context 'Renewal factory invoked with dental coverage' do

      let(:enrollment_status) { :coverage_selected }
      let(:coverage_kind)     { :dental }

      it 'should generate passive renewal' do
        expect(subject).to be_valid
        expect(subject.coverage_kind.to_sym).to eq coverage_kind
        expect(subject.sponsored_benefit_package).to eq benefit_package
        expect(subject.effective_on).to eq renewal_effective_date
        expect(subject.aasm_state).to eq 'auto_renewing'
        expect(subject.sponsored_benefit).to eq benefit_package.sponsored_benefit_for(coverage_kind)
        expect(subject.product).to eq enrollment.product.renewal_product
      end
    end
  end
end