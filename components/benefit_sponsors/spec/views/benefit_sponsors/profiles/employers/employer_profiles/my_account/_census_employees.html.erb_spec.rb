# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "views/benefit_sponsors/profiles/employers/employer_profiles/my_account/_census_employees.html.erb_spec.rb", :type => :view, dbclean: :after_each do

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

    before :each do
      census_employee.employee_role_id = employee_role.id
      census_employee.save

      view.extend BenefitSponsors::Engine.routes.url_helpers
      view.extend BenefitSponsors::ApplicationHelper
      view.extend ApplicationHelper
      view.extend BenefitSponsors::PermissionHelper
      view.extend EffectiveDatatablesHelper
      view.extend Config::AcaHelper

      assign(:employer_profile, employer_profile)
      allow(view).to receive(:plan_match_tool_is_enabled?).and_return(false)
      allow(view).to receive(:render_datatable).and_return(true)
      allow(view).to receive(:show_oop_pdf_link).and_return(false)
      allow(view).to receive(:env_bucket_name).and_return("dchbx-enroll-test-test")
    end

    it 'should display for HBX admin' do
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfile", updateable?: true, can_modify_employer?: true))
      render template: "benefit_sponsors/profiles/employers/employer_profiles/my_account/_census_employees.html.erb"
      expect(rendered).to match(/Terminate Employee Roster Enrollments/)
    end

    it 'should not display for employer' do
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfile", updateable?: true, can_modify_employer?: false))
      render template: "benefit_sponsors/profiles/employers/employer_profiles/my_account/_census_employees.html.erb"
      expect(rendered).to_not match(/Terminate Employee Roster Enrollments/)
    end

  end
end
