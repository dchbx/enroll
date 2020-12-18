# frozen_string_literal: true

require 'rails_helper'

module Operations
  module People
    # Spec for New Staff Operation
    module Roles
      RSpec.describe NewStaff, type: :model, dbclean: :after_each do
        before :all do
          DatabaseCleaner.clean
        end

        it 'should be a container-ready operation' do
          expect(subject.respond_to?(:call)).to be_truthy
        end

        context 'for failure case' do

          it 'should fail if person not found with given id' do
            result = subject.call({id: 'test'})
            expect(result.failure).to eq({:message => ['Person not found']})
          end
        end

        context 'for success case' do
          let(:person) {FactoryBot.create(:person)}

          it 'should return new staff entity' do
            result = subject.call({id: person.id })
            expect(result.value!).to be_a Entities::Staff
          end
        end
      end
    end
  end
end
