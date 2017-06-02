require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "clean_up_enrollments_in_cancel_state_erroneously")

describe CleanUpEnrollmentsInCancelStateErroneously do
  
  let(:given_task_name) { "clean_up_enrollments_in_cancel_state_erroneously" }
  subject { CleanUpEnrollmentsInCancelStateErroneously.new(given_task_name, double(:current_scope => nil)) }
  
  describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
  end
  
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  
  let(:e1) { FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       coverage_kind: "health",
                       effective_on: 2.months.ago.beginning_of_month,
                       enrollment_kind: "open_enrollment",
                       kind: "individual",
                       submitted_at: 3.months.ago.beginning_of_month,
                       terminated_on: 1.months.ago.beginning_of_month,
                       is_active: false,
                       aasm_state: 'coverage_terminated')
  }
  let(:e2) { FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       coverage_kind: "health",
                       effective_on: 2.months.ago.beginning_of_month,
                       enrollment_kind: "open_enrollment",
                       kind: "individual",
                       submitted_at: 3.months.ago.beginning_of_month,
                       is_active: true,
                       aasm_state: 'coverage_enrolled')
  }
  
  let!(:hbx_enrollment_member_one) { FactoryGirl.create(:hbx_enrollment_member, applicant_id:family.primary_family_member.id, eligibility_date: "2017-01-01", hbx_enrollment: e1) }
  let!(:hbx_enrollment_member_two) { FactoryGirl.create(:hbx_enrollment_member, applicant_id:family.primary_family_member.id, eligibility_date: "2017-01-01", hbx_enrollment: e2) }
  
  it "should check enrollments that were placed into the Terminated state erroneously" do
    expect(e1.effective_on).to eq (e2.effective_on)
    expect(e1.effective_on).to be > (e2.submitted_at)
    expect(e1.aasm_state).to eq "coverage_terminated"
  end
  
  it "updates erroneous effective date of e1" do
    subject.migrate
    e1.reload
    e2.reload
    expect(e1.terminated_on).to eq (e2.effective_on)
    expect(e1.aasm_state).to eq "coverage_expired"
  end
  
end