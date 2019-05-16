# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ModelEvents::RenewalApplicationSubmitted', dbclean: :after_each do
  let(:model_event) { "application_submitted" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
  let(:open_enrollment_start_on) {(TimeKeeper.date_of_record - 1.month).beginning_of_month}
  let(:current_effective_date)  { TimeKeeper.date_of_record }
  let(:prior_month_open_enrollment_start)  { TimeKeeper.date_of_record.beginning_of_month + Settings.aca.shop_market.open_enrollment.monthly_end_on - Settings.aca.shop_market.open_enrollment.minimum_length.days - 1.day}
  let(:valid_effective_date)   { (prior_month_open_enrollment_start - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).beginning_of_month }
  let(:benefit_application_end_on)   { (valid_effective_date + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day) }
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:person){ FactoryBot.create(:person, :with_family)}
  let!(:family) {person.primary_family}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id)}
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name) }
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
  end

  describe "when renewal employer's application is approved", dbclean: :after_each do
    context "ModelEvent" do

      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_application_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.approve_application!
      end
    end

    context "Notice Trigger", dbclean: :after_each do
      subject { BenefitSponsors::Observers::NoticeObserver.new }

      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:application_submitted, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_application_submitted"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_application_events(model_instance, model_event)
      end
    end

    context "NoticeBuilder", dbclean: :after_each do

      let(:data_elements) do
        [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.benefit_application.renewal_py_start_date",
          "employer_profile.broker.primary_fullname",
          "employer_profile.broker.organization",
          "employer_profile.broker.phone",
          "employer_profile.broker.email",
          "employer_profile.broker_present?"
        ]
      end
      let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { { "employer_id" => employer_profile.hbx_id.to_s, "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication", "event_object_id" => model_instance.id.to_s }}
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.approve_application!
      end

      context "when notice event received" do

        subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

        it "should return correct data model" do
          expect(merge_model).to be_a(recipient.constantize)
        end

        it "should return employer legal name" do
          expect(merge_model.employer_name).to eq employer_profile.organization.legal_name
        end

        it "should return plan year start date" do
          expect(merge_model.benefit_application.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
        end

        it "should return broker status" do
          expect(merge_model.broker_present?).to be_falsey
        end
      end
    end
  end
end
