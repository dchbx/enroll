# frozen_string_literal: true

require 'rails_helper'
require 'pry'

RSpec.describe FinancialAssistance::Operations::Applicant::Match, dbclean: :after_each do
  let(:params) do
    {:first_name => "sara",
     :last_name => "test",
     :ssn => "889984400",
     :dob => Date.today - 10.years}
  end

  # TODO: remove family association here once it is removed from the Application Model.
  let!(:application) { FactoryBot.create(:financial_assistance_application, family: ::Family.new) }
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      ssn: '889984400',
                      dob: (Date.today - 10.years),
                      first_name: 'sara',
                      last_name: 'test')
  end

  describe 'when valid applicant params passed' do
    context 'with ssn' do
      before do
        @result = subject.call(params: params, application: application)
      end

      it 'should be success' do
        expect(@result.success?).to be_truthy
      end

      it 'should return applicant object' do
        expect(@result.success).to eq(applicant)
      end
    end

    context 'without ssn' do
      before do
        applicant.update_attributes!(ssn: nil)
        params.merge!(ssn: nil)
        @result = subject.call(params: params, application: application)
      end

      it 'should be success' do
        expect(@result.success?).to be_truthy
      end

      it 'should return applicant object' do
        expect(@result.success).to eq(applicant)
      end
    end
  end

  describe 'when invalid applicant params passed' do
    before do
      @result = subject.call(params: {}, application: application)
    end

    it 'should be failure' do
      expect(@result.failure?).to be_truthy
    end

    it 'should return failure' do
      expect(@result.failure).to be_nil
    end
  end
end
