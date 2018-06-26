require 'rails_helper'

describe 'ModelEvents::SepRequestDenialNotice', :dbclean => :after_each  do
  let(:notice_event) { "sep_request_denial_notice" }
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, :aasm_state => 'enrolling' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id) }
  let(:employee_role_id) { FactoryGirl.create(:employee_role, person: person, census_employee: census_employee, employer_profile: employer_profile)}
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop") }
  let(:sep) { FactoryGirl.create(:special_enrollment_period, family: person.primary_family, qualifying_life_event_kind_id: qle.id) }
  let(:qle_reporting_deadline) {TimeKeeper.date_of_record}
  let(:qle_event_on) { qle_reporting_deadline.next_day}
  let(:notice_params) {
    {
      "qle_title" => qle.title,
      "qle_reporting_deadline" => qle_reporting_deadline.strftime('%m/%d/%Y'),
      "qle_event_on" => qle_event_on.strftime('%m/%d/%Y')
    }
  }

  before do
    allow(person).to receive_message_chain("primary_family.current_sep").and_return(nil)
  end

  describe "NoticeTrigger" do
    context "when employee matches er roster" do
      subject { Observers::NoticeObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.sep_request_denial_notice"
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.deliver(recipient: employee_role_id, event_object: plan_year, notice_event: "sep_request_denial_notice", notice_params: notice_params)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?",
        "employee_profile.special_enrollment_period.title",
        "employee_profile.special_enrollment_period.reporting_deadline",
        "employee_profile.special_enrollment_period.event_on",
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "employee_role_id" => employee_role_id,
        "event_object_kind" => "PlanYear",
        "event_object_id" => plan_year.id.to_s,
        "notice_params" => notice_params
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role_id)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq census_employee.employer_profile.legal_name
    end

    it "should return employee first name " do
      expect(merge_model.first_name).to eq person.first_name
    end

    it "should return employee last name " do
      expect(merge_model.last_name).to eq person.last_name
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end

    context "with QLE data_elements" do
      it "should return qle_title" do
        expect(merge_model.special_enrollment_period.title).to eq qle.title
      end

      it "should return qle_reporting_deadline" do
        expect(merge_model.special_enrollment_period.reporting_deadline).to eq qle_reporting_deadline.strftime('%m/%d/%Y')
      end

      it "should return qle_event_on" do
        expect(merge_model.special_enrollment_period.event_on).to eq qle_event_on.strftime('%m/%d/%Y')
      end
    end
  end
end