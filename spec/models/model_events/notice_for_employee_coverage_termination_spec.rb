require 'rails_helper'

describe 'ModelEvents::EmployeeCoverageTermination', dbclean: :after_each  do
  let(:model_event)  { "employee_coverage_termination" }
  let(:notice_event1) { "employer_notice_for_employee_coverage_termination" }
  let(:notice_event2) { "employee_notice_for_employee_coverage_termination" }
  let(:person){ FactoryGirl.create(:person, :with_family, :with_employee_role) }
  let(:family) { person.primary_family }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let(:employee_role) { person.employee_roles.first }
  let!(:model_instance) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: family.active_household, employee_role_id: employee_role.id, aasm_state: "coverage_enrolled", benefit_group_id: benefit_group.id) }
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name) }
  let!(:employer_staff_role) { FactoryGirl.create(:employer_staff_role, person: person, employer_profile_id: employer_profile.id)}

  describe "NoticeTrigger" do
    context "when employee terminates coverage" do
      subject { Observers::Observer.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:employee_coverage_termination, model_instance, {}) }

      it "should trigger notice event" do
        [notice_event1, notice_event2].each do |notice_event|
          expect(subject).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employer.#{notice_event}"
            expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end
          subject.trigger_notice(recipient: model_instance.employer_profile, event_object: model_instance, notice_event: notice_event)
        end
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "employer_profile.notice_date",
          "employer_profile.first_name",
          "employer_profile.last_name",
          "employer_profile.employer_name",
          "employer_profile.enrollment.coverage_end_on",
          "employer_profile.enrollment.enrolled_count",
          "employer_profile.enrollment.employee_first_name",
          "employer_profile.enrollment.employee_last_name",
          "employer_profile.enrollment.coverage_kind"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "HbxEnrollment",
        "event_object_id" => model_instance.id
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
      expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
    end

    it "should return employee first_name" do
      expect(merge_model.enrollment.employee_first_name).to eq model_instance.census_employee.first_name
    end

    it "should return employee last_name" do
      expect(merge_model.enrollment.employee_last_name).to eq model_instance.census_employee.last_name
    end

    it "should return enrollment terminated_on date " do
      expect(merge_model.enrollment.coverage_end_on).to eq model_instance.terminated_on
    end

    it "should return enrollment coverage_kind" do
      expect(merge_model.enrollment.coverage_kind).to eq model_instance.coverage_kind
    end

    it "should return enrollment covered dependents" do
      expect(merge_model.enrollment.enrolled_count).to eq model_instance.humanized_dependent_summary.to_s
    end

  end
end
