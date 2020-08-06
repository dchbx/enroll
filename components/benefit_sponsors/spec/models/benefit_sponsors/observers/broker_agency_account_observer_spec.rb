# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  module Observers
    RSpec.describe BrokerAgencyAccountObserver, type: :model, dbclean: :after_each do
      subject { BrokerAgencyAccountObserver.new }

      let!(:rating_area) { create(:benefit_markets_locations_rating_area) }

      let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:employer_organization)   { FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:employer_profile) { employer_organization.profiles.first }
      let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'shop', legal_name: 'Legal Name1', assigned_site: site) }
      let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, profile: employer_profile, benefit_market: site.benefit_markets.first) }

      before do
        allow(subject).to receive(:notify).exactly(1).times
      end

      context 'when employer hired a broker' do

        let(:account) { build :benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, benefit_sponsorship: benefit_sponsorship }

        before do
          subject.broker_hired?(account)
          subject.broker_fired?(account)
        end

        it 'should notify hired event' do
          sponsor = account.benefit_sponsorship.profile
          expect(subject).to have_received(:notify).with("acapi.info.events.employer.broker_added", {employer_id: sponsor.hbx_id, event_name: "broker_added"})
        end

        it 'should not notify fired event' do
          sponsor = account.benefit_sponsorship.profile
          expect(subject).not_to have_received(:notify).with("acapi.info.events.employer.broker_terminated", {employer_id: sponsor.hbx_id, event_name: "broker_terminated"})
        end
      end

      context 'when a family account hires a broker agency' do
        let(:broker_role) { FactoryBot.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
        let(:account) { build :benefit_sponsors_accounts_broker_agency_account, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, writing_agent_id: broker_role.id}

        before do
          subject.broker_hired?(account)
          subject.broker_fired?(account)
        end

        it 'should not notify hired event' do
          expect(subject).not_to have_received(:notify).with("acapi.info.events.employer.broker_added", {employer_id: employer_profile.hbx_id, event_name: "broker_added"})
        end

        it 'should not notify fired event' do
          expect(subject).not_to have_received(:notify).with("acapi.info.events.employer.broker_terminated", {employer_id: employer_profile.hbx_id, event_name: "broker_terminated"})
        end
      end

      context 'when employer fired a broker' do

        let(:account) { create :benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, benefit_sponsorship: benefit_sponsorship }

        before do
          account.assign_attributes({is_active: false, end_on: TimeKeeper.date_of_record})

          subject.broker_hired?(account)
          subject.broker_fired?(account)
        end

        it 'should notify fired event' do
          sponsor = account.benefit_sponsorship.profile
          expect(subject).to have_received(:notify).with("acapi.info.events.employer.broker_terminated", {employer_id: sponsor.hbx_id, event_name: "broker_terminated"})
        end

        it 'should not notify hired event' do
          sponsor = account.benefit_sponsorship.profile
          expect(subject).not_to have_received(:notify).with("acapi.info.events.employer.broker_added", {employer_id: sponsor.hbx_id, event_name: "broker_added"})
        end
      end
    end
  end
end
