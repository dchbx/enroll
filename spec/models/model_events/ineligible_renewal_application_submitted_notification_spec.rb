require 'rails_helper'

describe 'ModelEvents::InEligibleRenewalApplicationSubmittedNotification' do

  let(:model_event)  { "ineligible_renewal_application_submitted" }
  let(:notice_event) { "ineligible_renewal_application_submitted" }
  let(:effective_on) { Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months }
  let(:start_on) { (TimeKeeper.date_of_record - effective_on.months).beginning_of_month }

  let!(:employer) {
    FactoryGirl.create(:employer_with_renewing_planyear, start_on: start_on, renewal_plan_year_state: 'renewing_draft')
  }

  let(:model_instance) { employer.renewing_plan_year }

  let!(:renewing_employees) {
    employees = FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 5, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: employer,
      benefit_group: employer.active_plan_year.benefit_groups.first,
      renewal_benefit_group: model_instance.benefit_groups.first,
      created_at: TimeKeeper.date_of_record.prev_year)

    employees.each do |ce|
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer)
      ce.update_attributes({employee_role: employee_role})
    end    
  }

  describe "ModelEvent" do
    before :each do
     allow(employer).to receive(:is_primary_office_local?).and_return(false)
     allow(model_instance).to receive(:open_enrollment_date_errors).and_return(nil)
    end

    context "when In eligible renewal application created" do

      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :ineligible_renewal_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end

        model_instance.publish!
      end
    end
  end

  describe "NoticeTrigger" do

    before :each do
      allow(employer).to receive(:is_primary_office_local?).and_return(false)
    end

    context "when In eligible renewal application created" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:ineligible_renewal_application_submitted, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_renewal_eligibility_denial_notice"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        employer.census_employees.non_terminated.each do |ce|
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.termination_of_employers_health_coverage"
            expect(payload[:employee_role_id]).to eq ce.employee_role_id.to_s
            expect(payload[:event_object_kind]).to eq 'PlanYear'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end
        end

        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do
    let(:data_elements) {
      %w(employer_profile.employer_name employer_profile.plan_year.renewal_py_start_on employer_profile.first_name employer_profile.last_name
         employer_profile.plan_year.renewal_py_start_date employer_profile.broker.primary_fullname employer_profile.broker.organization
         employer_profile.broker.phone employer_profile.broker.email employer_profile.broker_present?)
     }

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }
    let(:staff_role) { double("Staff_role", first_name: "rspec", last_name: "mock" )}

    before :each do
      allow(employer).to receive(:staff_roles).and_return [staff_role]
      allow(employer).to receive(:is_primary_office_local?).and_return(false)
    end

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
        expect(merge_model.first_name).to eq employer.staff_roles.first.first_name
        expect(merge_model.employer_name).to eq employer.legal_name
        expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
        expect(merge_model.broker_present?).to be_falsey
        expect(merge_model.plan_year.renewal_py_start_on).to eq model_instance.start_on
      end
    end
  end
end
