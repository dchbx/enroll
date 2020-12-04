# frozen_string_literal: true

require 'rails_helper'

module Operations
  module People
    module Roles
      RSpec.describe PersistStaff, type: :model, dbclean: :after_each do
        before :all do
          DatabaseCleaner.clean
        end

        it 'should be a container-ready operation' do
          expect(subject.respond_to?(:call)).to be_truthy
        end

        context 'for failure case' do

          it 'should fail if profile not found with given id' do
            result = subject.call({profile_id: 'test'})
            expect(result.failure).to eq({:message => ['Profile not found']})
          end
        end

        context 'for success case' do
          let(:person) {FactoryBot.create(:person)}
          let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym)}
          let(:profile) { organization.employer_profile }

          it 'should return new staff entity' do
            result = subject.call({person_id: person.id, profile_id: profile.id })
            expect(result.value![:message]).to eq ["Successfully added employer staff role"]
          end
        end
      end
    end
  end
end
