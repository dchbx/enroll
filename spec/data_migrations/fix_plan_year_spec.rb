require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_plan_year")

describe FixPlanYear, dbclean: :after_each do

  let(:given_task_name) { "fix_plan_year_state" }
  subject { FixPlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating plan year and enrollments" do

    let(:organization) { FactoryGirl.create(:organization)}
    let(:benefit_group)     { FactoryGirl.build(:benefit_group, effective_on_kind: "date_of_hire")}
    let(:plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group]) }
    let!(:employer_profile)  { FactoryGirl.create(:employer_profile, organization: organization, plan_years: [plan_year]) }
    let (:term_date) {TimeKeeper.date_of_record.at_beginning_of_month.next_month}
    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, benefit_group_id:benefit_group.id,household: family.active_household)}

    context "termianted plan year to active plan year" do

      before :each do
        allow(ENV).to receive(:[]).with("fein").and_return organization.fein
        allow(ENV).to receive(:[]).with("start_on").and_return plan_year.start_on
        allow(ENV).to receive(:[]).with("end_on").and_return (plan_year.start_on-1.day) + 1.year
        allow(ENV).to receive(:[]).with("aasm_state").and_return 'active'
        allow(ENV).to receive(:[]).with("terminated_on").and_return ''
        plan_year.update_attributes(aasm_state:'terminated', terminated_on: term_date, end_on: term_date)
        hbx_enrollment.update_attributes(aasm_state:'coverage_terminated')
      end

      it "should make plan year & enrollments active " do
        expect(plan_year.aasm_state).to eq 'terminated'   # before migration
        expect(plan_year.terminated_on).to eq term_date
        expect(hbx_enrollment.aasm_state).to eq 'coverage_terminated'
        subject.migrate
        plan_year.reload
        hbx_enrollment.reload
        expect(plan_year.aasm_state).to eq 'active'  # after migration
        expect(plan_year.terminated_on).to eq nil
        expect(hbx_enrollment.aasm_state).to eq 'coverage_selected'
      end
    end

    context "termianted plan year to cancelled plan year" do

      before :each do
        allow(ENV).to receive(:[]).with("fein").and_return organization.fein
        allow(ENV).to receive(:[]).with("start_on").and_return plan_year.start_on
        allow(ENV).to receive(:[]).with("end_on").and_return (plan_year.start_on-1.day) + 1.year
        allow(ENV).to receive(:[]).with("aasm_state").and_return 'canceled'
        allow(ENV).to receive(:[]).with("terminated_on").and_return ''
        plan_year.update_attributes(aasm_state:'terminated', terminated_on: term_date, end_on: term_date)
        hbx_enrollment.update_attributes(aasm_state:'coverage_terminated')
      end

      it "should make plan year & enrollments active " do
        expect(plan_year.aasm_state).to eq 'terminated'   # before migration
        expect(plan_year.terminated_on).to eq term_date
        expect(hbx_enrollment.aasm_state).to eq 'coverage_terminated'
        subject.migrate
        plan_year.reload
        hbx_enrollment.reload
        expect(plan_year.aasm_state).to eq 'canceled'  # after migration
        expect(plan_year.terminated_on).to eq nil
        expect(hbx_enrollment.aasm_state).to eq 'coverage_canceled'
      end
    end
  end
end

