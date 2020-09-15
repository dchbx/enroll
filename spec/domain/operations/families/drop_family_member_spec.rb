# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Families::DropFamilyMember, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:person2) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
    person.ensure_relationship_with(per, 'child')
    person.save!
    per
  end
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member2) { FactoryBot.create(:family_member, family: family, person: person2) }

  describe 'drop family member' do
    context 'with valid arguments' do
      let(:params) do
        {family_id: family.id, family_member_id: family_member2.id}
      end

      before do
        @result = subject.call(params: params)
      end

      it 'should return success object' do
        expect(@result).to be_a(Dry::Monads::Result::Success)
      end

      it 'should return true' do
        expect(@result.success).to be_truthy
      end
    end

    context 'with invalid arguments' do
      let(:params) do
        {family_id: family.id, family_member_id: 'family_member2_id'}
      end

      before do
        @result = subject.call(params: params)
      end

      it 'should return failure object' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq("Family and family member Id's does not match")
      end
    end
  end
end
