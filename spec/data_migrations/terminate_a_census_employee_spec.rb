require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_a_census_employee")
describe TerminateACensusEmployee, dbclean: :after_each do
  let(:given_task_name) { "terminate a census_employee" }
  subject { TerminateACensusEmployee.new(given_task_name, double(:current_scope => nil)) }

  describe "changes the census employees aasm_state to terminated" do

    let(:site_key)              { Settings.site.key.to_sym }
    let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key) }
    let(:benefit_sponsor)       { create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{site_key}_employer_profile_initial_application".to_sym, site: site) }
    let(:benefit_sponsorship)   { benefit_sponsor.active_benefit_sponsorship }
    let(:employer_profile)      { benefit_sponsorship.profile }
    let!(:benefit_package)      { benefit_sponsorship.benefit_applications.first.benefit_packages.first}
    let!(:census_employee)      { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, benefit_group: benefit_package) }

    around do |example|
     ClimateControl.modify id: census_employee.id,
                           termination_date: (TimeKeeper.date_of_record - 30.days).to_s do
       example.run
     end
    end

    before(:each) do
      census_employee.update_attributes({:aasm_state => 'employee_role_linked'})
    end

    it "shoud have employee_role_linked" do
      expect(census_employee.aasm_state).to eq "employee_role_linked"
    end

    it "should have employment_terminated state" do
      subject.migrate
      census_employee.reload
      expect(census_employee.aasm_state).to eq "employment_terminated"
    end
  end
end
