# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::People::Find, dbclean: :after_each do

  let!(:person)            { FactoryBot.create(:person) }

  describe 'find person' do
    let(:valid_params) { {person_id: person.id} }
    let(:invalid_params) { {person_id: '123456789' } }

    it 'should return Person record' do
      result = subject.call(valid_params)

      expect(result.success?). to be_truthy
      expect(result.success). to be_a Person
    end

    it 'should throw an error' do
      result = subject.call(invalid_params)

      expect(result.success?). to be_falsey
      expect(result.failure[:message]). to eq(["Person not found"])
    end
  end
end
