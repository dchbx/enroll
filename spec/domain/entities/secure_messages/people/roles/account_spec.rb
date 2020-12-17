# frozen_string_literal: true

require 'rails_helper'

describe Entities::People::Roles::Account, "creating a role" do

  describe 'with valid arguments' do
    let(:input_params) do
      { name: "active test",
        kind: "test2",
        link: "http://test.com",
        status: :active,
        date: Date.today}
    end

    it 'should initialize' do
      expect(Entities::People::Roles::Account.new({roles: [input_params]})).to be_a Entities::People::Roles::Account
    end

    it 'should not raise error' do
      expect { Entities::People::Roles::Account.new({roles: [input_params]}) }.not_to raise_error
    end

    context 'for link as optional' do
      before do
        input_params.merge!({link: nil})
        @result = Entities::People::Roles::Account.new({roles: [input_params]})
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::People::Roles::Account
      end
    end

    context 'pull active roles' do
      before do
        input_params.merge!({link: nil})
        @result = Entities::People::Roles::Account.new({roles: [input_params]})
      end

      it 'should return active roles' do
        expect(@result.active_roles.length).to eq 1
        expect(@result.active_roles.first.name).to eq "active test"
      end
    end

    context 'pull pending roles' do

      let(:input_params) do
        { name: "pending test",
          kind: "test2",
          link: "http://test.com",
          status: :pending,
          date: Date.today}
      end

      before do
        input_params.merge!({link: nil})
        @result = Entities::People::Roles::Account.new({roles: [input_params]})
      end

      it 'should return pending roles' do
        expect(@result.pending_roles.length).to eq 1
        expect(@result.pending_roles.first.name).to eq "pending test"
      end
    end

    context 'pull inactive roles' do

      let(:input_params) do
        { name: "inactive test",
          kind: "test2",
          link: "http://test.com",
          status: :inactive,
          date: Date.today}
      end

      before do
        input_params.merge!({link: nil})
        @result = Entities::People::Roles::Account.new({roles: [input_params]})
      end

      it 'should return pending roles' do
        expect(@result.inactive_roles.length).to eq 1
        expect(@result.inactive_roles.first.name).to eq "inactive test"
      end
    end
  end

  describe 'with invalid arguments' do
    it 'should raise error' do
      expect { subject }.to raise_error(Dry::Struct::Error, /:roles is missing in Hash input/)
    end
  end
end