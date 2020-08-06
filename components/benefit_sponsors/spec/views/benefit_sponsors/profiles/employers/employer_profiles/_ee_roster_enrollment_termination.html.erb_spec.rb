# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "views/benefit_sponsors/profiles/employers/employer_profiles/_ee_roster_enrollment_termination.html.erb", :type => :view, dbclean: :after_each do

  context 'Terminate All Employees button' do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
    let(:effective_on) { current_effective_date }
    let(:aasm_state) { :active }
    let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
    let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}
    let(:employer_profile) { benefit_sponsorship.profile }
    let(:person) {FactoryBot.create(:person)}
    let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
    let!(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee, employer_profile: benefit_sponsorship.profile) }
    let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:enrollment_kind) { "open_enrollment" }
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        household: family.latest_household,
                        coverage_kind: "health",
                        family: family,
                        effective_on: effective_on,
                        enrollment_kind: enrollment_kind,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: current_benefit_package.id,
                        sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                        employee_role_id: employee_role.id)
    end

    before :each do
      census_employee.employee_role_id = employee_role.id
      census_employee.save
      view.extend BenefitSponsors::Engine.routes.url_helpers
    end

    context 'when employer had active application and enrollment' do
      it 'should have' do
        render "benefit_sponsors/profiles/employers/employer_profiles/ee_roster_enrollment_termination", employer_profile: employer_profile
        expect(rendered).to match(/Terminate All Employees for/)
      end
    end

    context 'when employer had no active application' do
      it 'should not have' do
        allow(employer_profile).to receive(:active_benefit_application).and_return(nil)
        render "benefit_sponsors/profiles/employers/employer_profiles/ee_roster_enrollment_termination", employer_profile: employer_profile
        expect(rendered).to_not match(/Terminate All Employees for/)
      end
    end
  end
end

