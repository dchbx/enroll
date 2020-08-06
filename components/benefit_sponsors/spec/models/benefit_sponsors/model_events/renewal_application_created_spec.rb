# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'BenefitSponsors::ModelEvents::RenewalApplicationCreated', dbclean: :around_each  do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:renewal_effective_date) { start_on }
  let(:current_effective_date) { start_on.prev_year }
  let(:employer_profile) { abc_profile }
  let!(:model_instance) { benefit_sponsorship.renewal_benefit_application }

  describe "when renewal application created" do
    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_application_events) do |_model_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_application_created, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.notify_on_create
        model_instance.save
      end
    end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:renewal_application_created, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_application_created"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
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
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.benefit_application.renewal_py_start_date",
        "employer_profile.benefit_application.renewal_py_submit_soft_due_date",
        "employer_profile.benefit_application.renewal_py_oe_end_date",
        "employer_profile.benefit_application.current_py_start_on.year",
        "employer_profile.benefit_application.renewal_py_start_on.year",
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

    let(:payload)   do
      {
        "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
        "event_object_id" => model_instance.id
      }
    end

    let(:soft_dead_line) { Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline) }

    context "when notice event delivered" do
      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.notify_on_create
        model_instance.save
      end

      it "should retrun merge mdoel" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return current plan year start_date" do
        expect(merge_model.benefit_application.current_py_start_on).to eq model_instance.start_on.prev_year
      end

      it "should return renewal plan_year start_date" do
        expect(merge_model.benefit_application.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return renewal plan_year soft_dead_line" do
        expect(merge_model.benefit_application.renewal_py_submit_soft_due_date).to eq soft_dead_line.strftime('%m/%d/%Y')
      end

      it "should return renewal plan_year open_enrollment_end_date" do
        expect(merge_model.benefit_application.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
