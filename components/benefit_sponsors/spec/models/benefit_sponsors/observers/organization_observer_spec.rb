require 'rails_helper'

module BenefitSponsors
  module Observers
    RSpec.describe OrganizationObserver, type: :model, dbclean: :after_each do
      let!(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_cca_employer_profile) }
      let(:subject) { BenefitSponsors::Organizations::Organization}
      let(:observer_instance) { OrganizationObserver.new }

      context 'organization legal_name changed' do

        it 'should send notification' do
          allow_any_instance_of(OrganizationObserver).to receive(:notify)
          expected_payload = {:employer_id => organization.hbx_id, :event_name => "name_changed"}

          organization.update_attributes!(legal_name: "test1234")

          subject.observer_peers.each do |observer, _|
            expect(observer).to have_received(:notify).with("acapi.info.events.employer.name_changed", expected_payload)
          end
        end

        it 'do not send notification' do
          organization.update_attributes!(dba: "virtual")

          subject.observer_peers.each do |observer, _|
            expect(observer).not_to receive(:notify)
          end
        end
      end

      describe '.update' do
        context 'has to send notification when' do
          it 'fein updated' do
            allow_any_instance_of(OrganizationObserver).to receive(:notify)
            organization.assign_attributes(fein: "987654532")
            observer_instance.update(organization, nil)
            expect(observer_instance).to have_received(:notify).with('acapi.info.events.employer.fein_corrected', {:employer_id=> organization.hbx_id, :event_name=>"fein_corrected"})
          end
        end
      end
    end
  end
end
