require 'rails_helper'
require 'rake'

describe 'terminating employer active plan year & enrollments' do
  describe 'migrations:terminate_employer_account' do


    let(:active_plan_year)  { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on: TimeKeeper.date_of_record.end_of_month, aasm_state: 'active') }
    let(:employer_profile)     { FactoryGirl.build(:employer_profile, plan_years: [active_plan_year]) }
    let(:organization) { FactoryGirl.create(:organization,employer_profile:employer_profile)}
    before do
      load File.expand_path("#{Rails.root}/lib/tasks/migrations/terminate_employer_accounts.rake", __FILE__)
      Rake::Task.define_task(:environment)
      fein = organization.fein
      end_on = TimeKeeper.date_of_record.end_of_month.strftime('%m/%d/%Y')
      termination_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      Rake::Task["migrations:terminate_employer_account"].invoke(fein,end_on,termination_date)
    end

    it 'should terminate plan year and update plan year end_on and terminated date' do
      active_plan_year.reload
      expect(active_plan_year.end_on).to eq TimeKeeper.date_of_record.end_of_month
      expect(active_plan_year.terminated_on).to eq TimeKeeper.date_of_record
      expect(active_plan_year.aasm_state).to eq "terminated"
    end

    it 'should not terminate published plan year' do
      active_plan_year.update_attribute(:aasm_state,'published')
      active_plan_year.reload
      expect(active_plan_year.end_on).to eq active_plan_year.end_on
      expect(active_plan_year.terminated_on).to eq nil
      expect(active_plan_year.aasm_state).to eq "published"
    end
  end
end