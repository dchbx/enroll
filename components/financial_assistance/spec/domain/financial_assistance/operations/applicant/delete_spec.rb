# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Applicant::Delete, dbclean: :after_each do

  let(:family_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft") }
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      ssn: '889984400',
                      dob: (Date.today - 10.years),
                      first_name: 'james',
                      last_name: 'bond')
  end

  let!(:applicant2) do
    FactoryBot.create(:financial_assistance_applicant,
                      ssn: '889984400',
                      dob: (Date.today - 10.years),
                      first_name: 'test',
                      last_name: 'person1')
  end

  describe 'when a draft application is present with an applicant' do

    it 'should be delete the applicant' do
      expect(application.applicants.count).to eq 1
      subject.call(financial_applicant: applicant, family_id: family_id)
      expect(application.reload.applicants.count).to eq 0
    end
  end

  describe "when there is no application" do
    it 'should not delete the applicant' do
      application.update!(aasm_state: "determined")
      result = subject.call(financial_applicant: applicant, family_id: family_id)
      expect(result.failure?).to be_truthy
    end
  end

  describe "When there is no applicant" do
    it 'should not delete the applicant' do
      result = subject.call(financial_applicant: applicant2, family_id: family_id)
      expect(result.failure?).to be_truthy
    end 
  end
end
