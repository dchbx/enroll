require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_special_enrollment_period_effective_date")

describe UpdateSpecialEnrollmentPeriodEffectiveDate, dbclean: :after_each do
  let(:given_task_name) { "update_special_enrollment_period_effective_date" }
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind, market_kind: 'shop') }
  let(:organization) { FactoryGirl.create(:organization, :with_expired_and_active_plan_years)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: organization.employer_profile, dob: TimeKeeper.date_of_record - 30.years, hired_on: "2014-11-11", ssn: '123456222') }
  let(:person) { FactoryGirl.create(:person_with_employee_role, census_employee_id: census_employee.id, employer_profile_id: organization.employer_profile.id, hired_on: "2014-11-11", ssn: '123456222') }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
  let(:sep) { FactoryGirl.create(:special_enrollment_period, family: family) }
  let(:effective_date) { sep.start_on + 2.days }
  subject { UpdateSpecialEnrollmentPeriodEffectiveDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  before do
    allow(ENV).to receive(:[]).with('special_enrollment_period_id').and_return sep.id
    allow(ENV).to receive(:[]).with('effective_date').and_return effective_date
  end

  describe "update special enrollment period effective date", dbclean: :after_each do
    it "should update special enrollment period effective date" do
      subject.migrate
      sep.reload
      expect(sep.next_poss_effective_date).to eq effective_date
    end
  end
end
