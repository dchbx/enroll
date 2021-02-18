# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::ModelEvents::BenefitApplication, dbclean: :after_each do

  let!(:nonpayment_model_event) { "benefit_coverage_period_terminated_nonpayment" }
  let(:voluntary_model_event) { "benefit_coverage_period_terminated_voluntary" }
  let(:carrier_drop_model_event) { "benefit_coverage_renewal_carrier_dropped" }
  let(:reinstated_model_event) { "benefit_coverage_period_reinstated" }
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
  let!(:parent_reinstated_instance) do
    FactoryBot.create(
      :benefit_sponsors_benefit_application,
      :with_benefit_package,
      :benefit_sponsorship => benefit_sponsorship,
      :aasm_state => 'draft',
      :effective_period => (start_on - 9.months)..start_on.end_of_month
    )
  end
  let!(:reinstated_model_instance) do
    FactoryBot.create(
      :benefit_sponsors_benefit_application,
      :with_benefit_package,
      :benefit_sponsorship => benefit_sponsorship,
      :aasm_state => 'draft',
      reinstated_id: parent_reinstated_instance.id,
      :effective_period => (start_on - 9.months)..start_on.end_of_month
    )
  end

  shared_examples_for "for employer plan year action" do |action, event|
    it "should create model event and should have attributes" do
      model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::EdiObserver }.each do |observer|
        expect(observer).to receive(:process_application_edi_events) do |model_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => event.to_sym, :klass_instance => model_instance, :options => {observer_klass: BenefitSponsors::Observers::EdiObserver})
        end
        if action == "cancel"
          model_instance.cancel!
        else
          model_instance.termination_kind = action
          model_instance.terminate_enrollment!
        end
      end
    end
  end

  shared_examples_for "for employer plan year action reinstated" do |action, event|
    it "should create model event and should have attributes" do
      reinstated_model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::EdiObserver }.each do |observer|
        expect(observer).to receive(:process_application_edi_events) do |reinstated_model_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => event.to_sym, :klass_instance => reinstated_model_instance, :options => {observer_klass: BenefitSponsors::Observers::EdiObserver})
        end
        if action == "reinstated"
          reinstated_model_instance.reinstate!
          reinstated_model_instance.activate_enrollment!
        end
      end
    end
  end

  describe "Employer ModelEvent" do
    it_behaves_like "for employer plan year action", "nonpayment", "benefit_coverage_period_terminated_nonpayment"
    it_behaves_like "for employer plan year action", "voluntary", "benefit_coverage_period_terminated_voluntary"
    it_behaves_like "for employer plan year action", "cancel", "benefit_coverage_renewal_carrier_dropped"
    it_behaves_like "for employer plan year action reinstated", "reinstated", "benefit_coverage_period_reinstated"
  end
end
