# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'ModelEvents::EmployeeOpenEnrollmentReminder', :dbclean => :after_each  do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:notice_event) { "employee_open_enrollment_reminder" }
  let(:aasm_state) { :enrollment_open }
  let(:current_effective_date)  { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:open_enrollment_start_on)  { TimeKeeper.date_of_record.beginning_of_month }
  let(:open_enrollment_period) { open_enrollment_start_on..(open_enrollment_start_on + 9.days) }
  let(:model_instance) {initial_application}
  let(:person){ FactoryBot.create(:person, :with_family)}
  let(:family) {person.primary_family}
  let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id)}
  let(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile) }
  let(:date_mock_object) { Date.new(current_effective_date.year, current_effective_date.prev_month.month, (Settings.aca.shop_market.open_enrollment.monthly_end_on - 2))}

  before do
    census_employee.update_attributes(employee_role_id: employee_role.id)
    census_employee.update_attributes!(created_at: current_effective_date.prev_year)
    TimeKeeper.set_date_of_record_unprotected!(date_mock_object)
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(TimeKeeper.date_of_record)
  end

  describe "ModelEvent" do
    it "should trigger model event" do
      model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_application_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
        end
        expect(observer).to receive(:process_application_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :open_enrollment_end_reminder_and_low_enrollment, :klass_instance => model_instance, :options => {})
        end
      end
      BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(date_mock_object)
    end
  end


  describe "NoticeTrigger" do
    context "2 days before open enrollment end date" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:open_enrollment_end_reminder_and_low_enrollment, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_open_enrollment_reminder"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.low_enrollment_notice_for_employer"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_application_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) do
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.benefit_application.current_py_oe_end_date",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    end

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {"event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication", "event_object_id" => model_instance.id }}
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
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

    it "should return open enrollment end on" do
      expect(merge_model.benefit_application.current_py_oe_end_date).to eq initial_application.open_enrollment_end_on.strftime('%m/%d/%Y')
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end

    context 'for renewing plan year' do
      include_context "setup renewal application"
      let(:payload) { { "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication", "event_object_id" => model_instance.id } }

      it 'should return renewing plan year open enrollment end on' do
        expect(merge_model.benefit_application.current_py_oe_end_date).to eq renewal_application.open_enrollment_end_on.strftime('%m/%d/%Y')
      end
    end
  end
end