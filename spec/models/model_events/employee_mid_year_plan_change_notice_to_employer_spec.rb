require 'rails_helper'

describe 'ModelEvents::EmployeeMidYearPlanChangeNoticeToEmployer', :dbclean => :after_each do
  let(:notice_event) { "employee_mid_year_plan_change_notice_to_employer" }
  let!(:employer_profile) { create(:employer_profile) }
  let(:person){ FactoryGirl.create(:person, :with_family, :with_employee_role) }
  let(:family) { person.primary_family }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let(:employee_role) { person.employee_roles.first }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: family.active_household, employee_role_id: employee_role.id, aasm_state: "coverage_enrolled", benefit_group_id: benefit_group.id) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }


  describe "NoticeTrigger" do
    context "when employees made mid-year plan change in their account" do
      subject { Observers::Observer.new }
      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employee_mid_year_plan_change_notice_to_employer"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq hbx_enrollment.id.to_s
        end
        subject.trigger_notice(recipient: employer_profile, event_object: hbx_enrollment, notice_event: "employee_mid_year_plan_change_notice_to_employer")
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.enrollment.employee_first_name",
        "employer_profile.enrollment.employee_last_name",
        "employer_profile.enrollment.coverage_start_on",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker_present?"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "HbxEnrollment",
        "event_object_id" => hbx_enrollment.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
      employee_role.update_attributes(census_employee_id: census_employee.id)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return employee first_name" do
      expect(merge_model.enrollment.employee_first_name).to eq hbx_enrollment.census_employee.first_name
    end

    it "should return employee last_name" do
      expect(merge_model.enrollment.employee_last_name).to eq hbx_enrollment.census_employee.last_name
    end

    it "should return enrollment effective date " do
      expect(merge_model.enrollment.coverage_start_on).to eq hbx_enrollment.effective_on.strftime('%m/%d/%Y')
    end
  end
end