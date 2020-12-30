require 'rails_helper'

module BenefitSponsors
  module Observers
    RSpec.describe OrganizationObserver, type: :model, dbclean: :after_each do
      let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_cca_employer_profile) }
      let(:subject) { BenefitSponsors::Organizations::Organization}
      let(:observer_instance) { OrganizationObserver.new }

      describe '.update' do
        context 'has to send notification when' do
          it 'fein updated' do
            allow_any_instance_of(OrganizationObserver).to receive(:notify)
            organization.assign_attributes(fein: "987654532")
            observer_instance.update(organization, nil)
            expect(observer_instance).to have_received(:notify).with('acapi.info.events.employer.fein_corrected', {:employer_id=> organization.hbx_id, :event_name=>"fein_corrected"})
          end

          it 'DBA updated' do
            allow_any_instance_of(OrganizationObserver).to receive(:notify)
            organization.assign_attributes(dba: "test")
            observer_instance.update(organization, nil)
            expect(observer_instance).to have_received(:notify).with('acapi.info.events.employer.name_changed', {:employer_id => organization.hbx_id, :event_name => "name_changed"})
          end

          it 'legal_name updated' do
            allow_any_instance_of(OrganizationObserver).to receive(:notify)
            organization.assign_attributes(legal_name: "test")
            observer_instance.update(organization, nil)
            expect(observer_instance).to have_received(:notify).with('acapi.info.events.employer.name_changed', {:employer_id => organization.hbx_id, :event_name => "name_changed"})
          end
        end
      end
    end
  end
end
