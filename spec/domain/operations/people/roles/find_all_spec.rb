# frozen_string_literal: true

require 'rails_helper'

module Operations
  module People
    # Spec for Find All Operation
    module Roles
      RSpec.describe FindAll, type: :model, dbclean: :after_each do
        before :all do
          DatabaseCleaner.clean
        end

        it 'should be a container-ready operation' do
          expect(subject.respond_to?(:call)).to be_truthy
        end

        context 'for failure case' do
          it 'should throw missing key if ID is not passed' do
            result = subject.call({})
            expect(result.failure).to eq('Missing Key')
          end

          it 'should fail if person is not found' do
            result = subject.call({id: 'test'})
            expect(result.failure).to eq({:message => ['Person not found']})
          end
        end

        context 'for success case' do
          let(:person) {FactoryBot.create(:person, :with_active_consumer_role)}
          let!(:consumer_role) {FactoryBot.create(:consumer_role, person: person)}
          let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
          let!(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
          let(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
          let!(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active', person: person)}


          it 'should return entity with person role details' do
            result = subject.call({id: person.id })
            expect(result.value!).to be_a Entities::People::Roles::Account
            expect(result.value!.roles.length).to eq 2
          end

          it 'should return active role' do
            result = subject.call({id: person.id })
            expect(result.value!.active_roles.length).to eq 2
          end

          it 'should return inactive roles' do
            broker_agency_staff_role.update_attributes(aasm_state: "broker_agency_terminated")
            result = subject.call({id: person.id })
            expect(result.value!.inactive_roles.length).to eq 1
            expect(result.value!.inactive_roles.first.kind).to eq "Broker Staff"
          end

          it 'should return pending roles' do
            broker_agency_staff_role.update_attributes(aasm_state: "broker_agency_pending")
            result = subject.call({id: person.id })
            expect(result.value!.pending_roles.length).to eq 1
            expect(result.value!.pending_roles.first.kind).to eq "Broker Staff"
          end
        end
      end
    end
  end
end