# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::GeneralAgencyHiredNotice', dbclean: :around_each  do

  let(:start_on) { TimeKeeper.date_of_record }
  let(:person) { FactoryBot.create(:person) }
  let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
  let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let(:employer_profile)    { organization.employer_profile }
  let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

  let(:broker_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
  let(:broker_agency_profile)  { broker_agency.broker_agency_profile }

  let(:broker_agency_old) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
  let(:broker_agency_profile_old)  { broker_agency.broker_agency_profile }

  let(:general_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site)}
  let(:general_agency_profile) {general_agency.profiles.first }

  let(:broker_model_instance)          { broker_agency_profile }
  let(:broker_agency_account) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, employer_profile: employer_profile, broker_agency_profile: broker_agency_profile, is_active: true) }

  let(:plan_design_organization) { FactoryBot.create(:sponsored_benefits_plan_design_organization, sponsor_profile_id: employer_profile.id) }
  let(:ga_model_instance) { plan_design_organization.general_agency_accounts.build(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }

  describe "when a GA is hired" do
    context "ModelEvent" do

      context "employer hires a broker and broker has default GA assigned" do

        before do
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
        end

        it "should trigger notice" do
          ga_model_instance.class.observer_peers.each_key do |observer|
            expect(observer).to receive(:process_ga_account_events) do |_instance, model_event|
              expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_hired, :klass_instance => ga_model_instance, :options => {})
            end
          end
          ga_model_instance.save
        end
      end

      context "employer changes broker and broker has default GA assigned" do

        before do
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
        end

        let(:broker_agency_account_old) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, employer_profile: employer_profile, broker_agency_profile: broker_agency_profile, is_active: true) }
        let(:model_instance)  { plan_design_organization.general_agency_accounts.build(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }

        it "should trigger notice" do
          model_instance.class.observer_peers.each_key do |observer|
            expect(observer).to receive(:process_ga_account_events) do |_instance, model_event|
              expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_hired, :klass_instance => model_instance, :options => {})
            end
          end
          model_instance.save
        end
      end

      context "broker assigns GA to an employer" do

        let(:model_instance)  { plan_design_organization.general_agency_accounts.build(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }

        it "should trigger notice" do
          model_instance.class.observer_peers.each_key do |observer|
            expect(observer).to receive(:process_ga_account_events) do |_instance, model_event|
              expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_hired, :klass_instance => model_instance, :options => {})
            end
          end
          model_instance.save
        end
      end
    end

    context "NoticeTrigger" do
      context 'when general agency account is the event object' do
        let(:subject)     { BenefitSponsors::Observers::NoticeObserver.new }
        let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:general_agency_hired, ga_model_instance, {}) }

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.general_agency.general_agency_hired_confirmation_to_agency"
            expect(payload[:event_object_kind]).to eq "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile"
            expect(payload[:event_object_id]).to eq employer_profile.id.to_s
          end
          subject.process_ga_account_events(ga_model_instance, model_event)
        end
      end
    end
  end

  describe "NoticeBuilder" do

    before do
      broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
      broker_agency_profile.primary_broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id)
      ga_model_instance.save
    end

    let(:broker_role) { broker_agency_profile.primary_broker_role }
    let!(:employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let(:data_elements) do
      [
          'general_agency.notice_date',
          'general_agency.legal_name',
          'general_agency.employer_name',
          'general_agency.first_name',
          'general_agency.last_name',
          'general_agency.assignment_date',
          'general_agency.broker.primary_fullname',
          'general_agency.employer_poc_firstname',
          'general_agency.employer_poc_lastname',
          'general_agency.'
      ]
    end

    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::GeneralAgency" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    context "when event is triggered with general_agency_account update" do

      let(:payload) do
        {
          "event_object_kind" => "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile",
          "event_object_id" => employer_profile.id.to_s,
          "notice_params" => { "general_agency_account_id" => ga_model_instance.id.to_s }
        }
      end

      before do
        allow(subject).to receive(:resource).and_return(general_agency_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should return merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return notice date' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it 'should return general agency legal name' do
        expect(merge_model.legal_name).to eq general_agency_profile.legal_name
      end

      it 'should return general agency - employer assignment date' do
        expect(merge_model.assignment_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it 'should return employer poc first name' do
        expect(merge_model.employer_poc_firstname).to eq employer_staff_role.person.first_name
      end

      it 'should return employer poc last name' do
        expect(merge_model.employer_poc_lastname).to eq employer_staff_role.person.last_name
      end

      it 'should return broker primary fullname' do
        expect(merge_model.broker.primary_fullname).to eq broker_role.person.full_name
      end
    end
  end
end