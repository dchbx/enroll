require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'change_aasm_state_dot_census_employee')
describe ChangeAasmStateDotCensusEmployee, dbclean: :after_each do
  describe 'given a task name' do
    let(:given_task_name) { 'change_aasm_state_dot_census_employee' }
    subject {ChangeAasmStateDotCensusEmployee.new(given_task_name, double(:current_scope => nil)) }
      it 'has the given task name' do
        expect(subject.name).to eql given_task_name
      end
    end
  describe 'census employee not in terminated state' do
    subject {ChangeAasmStateDotCensusEmployee.new('change_aasm_state_dot_census_employee', double(:current_scope => nil)) }

    let(:site_key)              { Settings.site.key.to_sym }
    let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key) }
    let(:benefit_sponsor)       { create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{site_key}_employer_profile_initial_application".to_sym, site: site) }
    let(:benefit_sponsorship)   { benefit_sponsor.active_benefit_sponsorship }
    let(:employer_profile)      { benefit_sponsorship.profile }
    let!(:benefit_package)      { benefit_sponsorship.benefit_applications.first.benefit_packages.first}
    let!(:census_employee)      { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, benefit_group: benefit_package) }

    before :each do
      census_employee.update_attributes!(aasm_state:'employment_terminated',employment_terminated_on:TimeKeeper.date_of_record,coverage_terminated_on:TimeKeeper.date_of_record)
    end
    
    it 'should change dot of ce not in employment termination state' do
      ClimateControl.modify census_employee_id: census_employee.id do
        subject.migrate
        census_employee.reload
        expect(census_employee.employment_terminated_on).to eq nil
        expect(census_employee.coverage_terminated_on).to eq nil
        expect(census_employee.aasm_state).to eq 'employee_role_linked'
      end
    end
  end 
end
