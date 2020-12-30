# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Types  do

  describe "Types::PositiveInteger" do
    let(:positive_integer)   { 1 }
    let(:negative_integer)   { -1 }
    let(:integer_string)     { '22' }
    let(:float)              { 2.2 }

    subject(:type) { Types::PositiveInteger }

    it 'a correct value is valid' do
      expect(type[positive_integer]).to be_truthy
      expect(type[integer_string]).to be_truthy
      expect(type[float]).to be_truthy
    end

    it 'an incorrect value is not valid' do
      expect{type[negative_integer]}.to raise_error Dry::Types::ConstraintError
    end

    it 'an coerces a correct value string type to integer' do
      expect(type[1]).to eq(positive_integer)
      expect(type[integer_string]).to eq(22)
    end
  end

  describe "Types::Bson" do
    let(:valid_key)           { BSON::ObjectId.new }
    let(:valid_key_string)    { '5e88e708b72a3baf8cc83f16' }
    let(:invalid_key_string)  { '5e88e708b72a3b' }
    let(:invalid_key_symbol)  { :invalid_id }
    let(:invalid_key)         { 'invalid_id' }

    subject(:type)            { Types::Bson }

    it 'a correct value is valid' do
      expect(type[valid_key]).to be_truthy
      expect(type[valid_key_string]).to be_truthy
    end

    it 'an incorrect value is not valid' do
      expect{type[invalid_key_string]}.to raise_error  BSON::ObjectId::Invalid
      expect{type[invalid_key_symbol]}.to raise_error  BSON::ObjectId::Invalid
      expect{type[invalid_key]}.to raise_error  BSON::ObjectId::Invalid
    end

    it 'an coerces a correct value string type to BSON::ObjectId' do
      expect(type[valid_key]).to be_a(BSON::ObjectId)
      expect(type[valid_key_string]).to be_a(BSON::ObjectId)
    end
  end

end