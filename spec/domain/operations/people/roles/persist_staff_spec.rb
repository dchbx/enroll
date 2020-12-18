# frozen_string_literal: true

require 'rails_helper'

module Operations
  module People
    # Spec for Persist Staff Operation
    module Roles
      RSpec.describe PersistStaff, type: :model, dbclean: :after_each do
        before :all do
          DatabaseCleaner.clean
        end

        it 'should be a container-ready operation' do
          expect(subject.respond_to?(:call)).to be_truthy
        end

        let(:person) {FactoryBot.create(:person)}
        let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym)}
        let(:profile) { organization.employer_profile }

        let(:params) do
          {
            first_name: person.first_name,
            last_name: person.last_name,
            profile_id: profile.id.to_s,
            person_id: person.id.to_s,
            coverage_record: {
              is_applying_coverage: false,
              address: {},
              email: {}
            }
          }
        end

        context 'for failure case' do

          it 'should fail if profile not found with given id' do
            result = subject.call(params.merge!({profile_id: 'test' }))
            expect(result.failure).to eq({:message => 'Profile not found'})
          end
        end

        context 'for success case' do

          it 'should return new staff entity' do
            result = subject.call(params)
            expect(result.value![:message]).to eq "Successfully added employer staff role"
          end
        end
      end
    end
  end
end
