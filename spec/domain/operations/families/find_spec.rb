# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Families::Find, dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

  describe 'family find' do
    context 'when family id passed' do

      it 'should return family' do
        result = subject.call(id: family.id)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.success).to eq family
      end
    end

    context 'when invalid params passed' do
      it 'should return failure' do
        result = subject.call(id: '464523234')
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq "Unable to find Family with ID 464523234."
      end
    end
  end
end