# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::EmployerRenewalEligibilityDenialNotice', dbclean: :after_each  do
  let(:notice_event) { "employer_renewal_eligibility_denial_notice" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
  let(:open_enrollment_start_on) {(TimeKeeper.date_of_record - 1.month).beginning_of_month}
  let(:current_effective_date)  { TimeKeeper.date_of_record }
  let(:prior_month_open_enrollment_start)  { TimeKeeper.date_of_record.beginning_of_month + Settings.aca.shop_market.open_enrollment.monthly_end_on - Settings.aca.shop_market.open_enrollment.minimum_length.days - 1.day}
  let(:valid_effective_date)   { (prior_month_open_enrollment_start - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).beginning_of_month }
  let(:benefit_application_end_on)   { (valid_effective_date + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day) }
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:benefit_market) { site.benefit_markets.first }
  let!(:benefit_market_catalog) do
    create(:benefit_markets_benefit_market_catalog, :with_product_packages,
           benefit_market: benefit_market,
           title: "SHOP Benefits for #{current_effective_date.year}",
           application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
  end
  let!(:model_instance) do
    application = FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package,
                                    benefit_sponsorship: benefit_sponsorship,
                                    effective_period: start_on..start_on.next_year.prev_day,
                                    open_enrollment_period: open_enrollment_start_on..open_enrollment_start_on + 20.days)
    application.benefit_sponsor_catalog.save!
    application
  end

  before :each do
    allow(model_instance).to receive(:is_renewing?).and_return(true)
    allow(employer_profile).to receive(:is_primary_office_local?).and_return(false)
  end

  describe "when renewal employer denial" do

    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_application_events) do |_model_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :ineligible_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.submit_for_review!
      end
    end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:ineligible_application_submitted, model_instance, {}) }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_renewal_eligibility_denial_notice"
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
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?"
      ]
    end

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload) { { "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication", "event_object_id" => model_instance.id }}
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
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

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end
end
