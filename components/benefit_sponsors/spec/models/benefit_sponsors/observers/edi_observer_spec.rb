# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Observers::EdiObserver, dbclean: :after_each do

  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month}
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:model_instance) do
    FactoryBot.create(
      :benefit_sponsors_benefit_application,
      :with_benefit_package,
      :benefit_sponsorship => benefit_sponsorship,
      :aasm_state => 'active',
      :effective_period => start_on..(start_on + 1.year) - 1.day
    )
  end
  let!(:model_instance1) do
    FactoryBot.create(
      :benefit_sponsors_benefit_application,
      :with_benefit_package,
      :benefit_sponsorship => benefit_sponsorship,
      :aasm_state => 'reinstated',
      :effective_period => (start_on - 9.months)..start_on.end_of_month
    )
  end

  subject { BenefitSponsors::Observers::EdiObserver.new }

  shared_examples_for "employer event" do |event|
    let!(:event_type) {event.to_sym}

    let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(event_type, model_instance, {}) }

    it "deliver event should have" do
      expect(subject).to receive(:deliver) do |recipient:, event_object:,event_name:, edi_params: {}|
        expect(recipient).to eq model_instance.employer_profile
        expect(event_object).to eq model_instance
        expect(event_name).to eq event
        expect(edi_params[:plan_year_id]).to eq model_instance.id.to_s if event == "benefit_coverage_renewal_carrier_dropped"
      end
      subject.process_application_edi_events(model_instance, model_event)
    end

    it "notify event should have" do
      expect(subject.notifier).to receive(:notify) do |event_name, payload|
        expect(event_name).to eq "acapi.info.events.employer.#{event}"
        expect(payload[:employer_id]).to eq model_instance.employer_profile.hbx_id
        expect(payload[:is_trading_partner_publishable]).to eq false
        expect(payload[:event_name]).to eq event
        expect(payload[:plan_year_id]).to eq model_instance.id.to_s if event == "benefit_coverage_renewal_carrier_dropped"
      end
      subject.process_application_edi_events(model_instance, model_event)
    end
  end

  shared_examples_for "employer event for reinsated ben_app" do |event|
    let!(:event_type) {event.to_sym}

    let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(event_type, model_instance1, {}) }

    it "deliver event should have" do
      expect(subject).to receive(:deliver) do |recipient:, event_object:,event_name:, _edi_params: {}|
        expect(recipient).to eq model_instance1.employer_profile
        expect(event_object).to eq model_instance1
        expect(event_name).to eq event
      end
      subject.process_application_edi_events(model_instance1, model_event)
    end

    it "notify event should have" do
      expect(subject.notifier).to receive(:notify) do |event_name, payload|
        expect(event_name).to eq "acapi.info.events.employer.#{event}"
        expect(payload[:employer_id]).to eq model_instance1.employer_profile.hbx_id
        expect(payload[:is_trading_partner_publishable]).to eq false
        expect(payload[:event_name]).to eq event
      end
      subject.process_application_edi_events(model_instance1, model_event)
    end
  end

  describe "Notify Employer Plan Year Event" do
    it_behaves_like "employer event", "benefit_coverage_period_terminated_nonpayment"
    it_behaves_like "employer event", "benefit_coverage_period_terminated_voluntary"
    it_behaves_like "employer event", "benefit_coverage_renewal_carrier_dropped"
    it_behaves_like "employer event for reinsated ben_app", "benefit_coverage_period_reinstated"
  end
end
