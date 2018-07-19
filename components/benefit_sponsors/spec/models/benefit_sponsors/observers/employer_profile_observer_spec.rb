require 'rails_helper'

module BenefitSponsors
  module Observers
    RSpec.describe EmployerProfileObserver, type: :model, dbclean: :after_each do
      subject { EmployerProfileObserver.new }

      let(:employer_profile) { create :benefit_sponsors_organizations_aca_shop_cca_employer_profile, :with_organization_and_site }

      before do
        allow(subject).to receive(:notify)
      end

      context 'with an employer_profile with an address change' do
        before do
          employer_profile.class.add_observer subject
          employer_profile.assign_attributes office_locations_attributes: {
            '0' => {
              id: employer_profile.office_locations.first.id,
              address_attributes: {
                address_1: '1114 Cool St'
              }
            }
          }

          subject.update(employer_profile)
        end

        it 'sends a notification' do
          expect(subject).to have_received(:notify).with('acapi.info.events.employer.address_changed', {:employer_id=> employer_profile.hbx_id, :event_name=>"address_changed"})
        end
      end
    end
  end
end
