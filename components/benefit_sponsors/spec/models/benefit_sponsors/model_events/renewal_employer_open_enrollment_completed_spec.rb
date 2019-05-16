# frozen_string_literal: true

require 'rails_helper'

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'BenefitSponsors::ModelEvents::RenewalEmployerOpenEnrollmentCompleted', dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:renewal_state)            { :enrollment_open }
  let(:notice_event) { "renewal_employee_enrollment_confirmation" }
  let!(:person){ FactoryBot.create(:person, :with_family)}
  let!(:family) {person.primary_family}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id)}
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile) }

  let!(:model_instance) {renewal_application}
  let(:enrollment_policy) {instance_double("BenefitMarkets::BusinessRulesEngine::BusinessPolicy", success_results: "Success") }
  let!(:hbx_enrollment) do
    hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                                       household: family.active_household,
                                       aasm_state: "renewing_coverage_selected",
                                       effective_on: model_instance.start_on,
                                       rating_area_id: model_instance.recorded_rating_area_id,
                                       sponsored_benefit_id: model_instance.benefit_packages.first.health_sponsored_benefit.id,
                                       sponsored_benefit_package_id: model_instance.benefit_packages.first.id,
                                       benefit_sponsorship_id: model_instance.benefit_sponsorship.id,
                                       benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
                                       employee_role_id: employee_role.id)
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  end

  before do
    allow(model_instance).to receive(:is_renewing?).and_return(true)
    census_employee.update_attributes(employee_role_id: employee_role.id)
  end

  describe "ModelEvent" do
    it "should trigger model event" do
      model_instance.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_application_events) do |_model_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :employer_open_enrollment_completed, :klass_instance => model_instance, :options => {})
        end
      end
      allow_any_instance_of(BenefitMarkets::BusinessRulesEngine::BusinessPolicy).to receive(:is_satisfied?).with(model_instance).and_return true
      model_instance.end_open_enrollment!
    end
  end

  describe "NoticeTrigger" do
    context "open enrollment end" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:employer_open_enrollment_completed, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_employer_open_enrollment_completed"
          expect(payload[:employer_id]).to eq abc_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.renewal_employee_enrollment_confirmation"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role_id.to_s
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq hbx_enrollment.id.to_s
        end

        allow_any_instance_of(BenefitMarkets::BusinessRulesEngine::BusinessPolicy).to receive(:is_satisfied?).with(model_instance).and_return true
        subject.process_application_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder for Employer" do

    let(:data_elements) do
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.benefit_application.renewal_py_start_date",
        "employer_profile.benefit_application.renewal_py_submit_due_date",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?"
      ]
    end

    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload) { { "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication", "event_object_id" => model_instance.id }}

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(abc_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should retrun merge mdoel" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq abc_profile.legal_name
      end

      it "should return plan year start date" do
        expect(merge_model.benefit_application.renewal_py_start_date).to eq renewal_application.start_on.strftime('%m/%d/%Y')
      end

      it "should return publish due date" do
        due_date = Date.new(renewal_application.start_on.prev_month.year, renewal_application.start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month).strftime('%m/%d/%Y')
        expect(merge_model.benefit_application.renewal_py_submit_due_date).to eq due_date
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end

  describe "NoticeBuilder for Employee" do

    let(:data_elements) do
      [
        "employee_profile.notice_date",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.employer_name",
        "employee_profile.notice_date"
      ]
    end
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {"event_object_kind" => "HbxEnrollment", "event_object_id" => hbx_enrollment.id }}

    context "when notice event received" do
      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        employee_role.update_attributes(census_employee_id: census_employee.id)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice_date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employee first_name" do
        expect(merge_model.first_name).to eq employee_role.person.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.last_name).to eq employee_role.person.last_name
      end

      it "should return employer_name" do
        expect(merge_model.employer_name).to eq abc_profile.legal_name
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end
    end
  end
end
