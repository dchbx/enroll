# frozen_string_literal: true

require 'rails_helper'

describe Entities::People::Roles::Role, "creating a role" do

  describe 'with valid arguments' do
    let(:input_params) do
      { name: "test",
        kind: "test2",
        link: "http://test.com",
        status: :active,
        date: Date.today}
    end

    it 'should initialize' do
      expect(Entities::People::Roles::Role.new(input_params)).to be_a Entities::People::Roles::Role
    end

    it 'should not raise error' do
      expect { Entities::People::Roles::Role.new(input_params) }.not_to raise_error
    end

    context 'for link as optional' do
      before do
        input_params.merge!({link: nil})
        @result = Entities::People::Roles::Role.new(input_params)
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::People::Roles::Role
      end
    end

    context 'for date as optional' do
      before do
        input_params.merge!({date: nil})
        @result = Entities::People::Roles::Role.new(input_params)
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::People::Roles::Role
      end
    end
  end

  describe 'with invalid arguments' do
    it 'should raise error' do
      expect { subject }.to raise_error(Dry::Struct::Error, /:name is missing in Hash input/)
    end
  end

end