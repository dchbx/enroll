# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HbxEnrollments::Operations::FindModel, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, household: family.active_household, family: family) }

  let(:params) do
    {enrollment_id: hbx_enrollment.id.to_s}
  end

  context 'for success case' do
    before do
      @result = subject.call(params)
    end

    it 'should be a container-ready operation' do
      expect(subject.respond_to?(:call)).to be_truthy
      expect(@result.success?).to be_truthy
    end

    it 'should be HbxEnrollments instance' do
      expect(@result.success).to be_a HbxEnrollment
    end

    it 'should return enrollment object ' do
      expect(@result.success).to eq hbx_enrollment
    end

  end

  context 'for failure case' do
    before do
      @result = subject.call({enrollment_id: '1234'})
    end

    it 'should return failure' do
      expect(@result.failure?).to be_truthy
    end

    it 'should return errors message' do
      expect(@result.failure).to eq("enrollment not found hbx_id:1234")
    end
  end
end