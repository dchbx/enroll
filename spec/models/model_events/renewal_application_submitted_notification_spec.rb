require 'rails_helper'

describe 'ModelEvents::RenewalApplicationSubmittedNotification' do

  let(:model_event)  { "renewal_application_submitted" }
  let(:notice_event) { "renewal_application_published" }
  let(:start_on) { (TimeKeeper.date_of_record + 3.months).beginning_of_month }

  let!(:employer) { create(:employer_with_planyear, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year, plan_year_state: 'active') }
  let!(:model_instance) { build(:renewing_plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'renewing_draft', benefit_groups: [benefit_group]) }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let!(:employer_staff_role) {FactoryGirl.create(:employer_staff_role, aasm_state:'is_active', employer_profile_id: employer.id)}
  let(:person) { FactoryGirl.create(:person,employer_staff_roles:[employer_staff_role])}
  
  describe "ModelEvent" do
    context "when renewal application created" do
  
      it "should trigger model event" do 
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.publish!
        model_instance.save
      end
    end
  end

  describe "NoticeTrigger" do
    context "when renewal application created" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:renewal_application_submitted, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.zero_employees_on_roster_notice"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
         end

        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_application_published"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.plan_year.renewal_py_start_date",
        "employer_profile.plan_year.renewal_py_submit_soft_due_date",
        "employer_profile.plan_year.renewal_py_oe_end_date",
        "employer_profile.plan_year.current_py_start_on.year",
        "employer_profile.plan_year.renewal_py_start_on.year",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { { 
      "event_object_kind" => "PlanYear",
      "event_object_id" => model_instance.id
    } }

    let(:soft_dead_line) { Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline) }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.publish
        model_instance.save
      end

      it "should build the data elements for the notice" do
        merge_model = subject.construct_notice_object
        expect(merge_model).to be_a(recipient.constantize)
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
        expect(merge_model.employer_name).to eq employer.legal_name
        expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
        expect(merge_model.plan_year.renewal_py_submit_soft_due_date).to eq soft_dead_line.strftime('%m/%d/%Y')
        expect(merge_model.plan_year.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
        expect(merge_model.broker_present?).to be_falsey
        expect(merge_model.plan_year.renewal_py_start_on).to eq model_instance.start_on
      end 
    end
  end
end