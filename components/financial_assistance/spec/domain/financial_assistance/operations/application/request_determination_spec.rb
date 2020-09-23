# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Application::RequestDetermination, dbclean: :after_each do

  let!(:application) do
    application = FactoryBot.create(:financial_assistance_application, :with_applicants, family_id: BSON::ObjectId.new, aasm_state: 'draft')
    application
  end
  let(:create_elibility_determinations) do
    application.eligibility_determinations.delete_all
    application.eligibility_determinations.create({
                                                    max_aptc: 0,
                                                    csr_percent_as_integer: 0,
                                                    aptc_csr_annual_household_income: 0,
                                                    aptc_annual_income_limit: 0,
                                                    csr_annual_income_limit: 0,
                                                    hbx_assigned_id: 10_001
                                                  })
  end
  let(:set_terms_on_application) do
    application.update_attributes({
                                    :medicaid_terms => true,
                                    :submission_terms => true,
                                    :medicaid_insurance_collection_terms => true,
                                    :report_change_terms => true
                                  })
  end

  describe 'When Application in non submitted state passed' do
    let(:result) { subject.call(application_id: application.id) }

    it 'should fail with mssage' do
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq "Application is in #{application.aasm_state} state. Please submit application."
    end
  end

  describe 'When Application with valid information given' do
    before do
      allow(application).to receive(:relationships_complete?).and_return(true)
      allow(subject).to receive(:notify).and_return(true)
      set_terms_on_application
      application.submit!
      create_elibility_determinations
      application.applicants.each{|applicant| applicant.update(eligibility_determination_id: application.eligibility_determinations.first.id)}
    end

    it 'should publish payload successfully' do
      result = subject.call(application_id: application.id)
      expect(result.success?).to be_truthy
    end
  end

  describe 'When Application acceptance terms missing' do

    before do
      allow(application).to receive(:relationships_complete?).and_return(true)
      allow(subject).to receive(:notify).and_return(true)
      application.submit!
      create_elibility_determinations
      application.applicants.each{|applicant| applicant.update(eligibility_determination_id: application.eligibility_determinations.first.id)}
    end

    it 'should fail publish with schema validation errors' do
      result = subject.call(application_id: application.id)
      expect(result.failure?).to be_truthy
      %w[has_accepted_medicaid_terms has_accepted_medicaid_insurance_collection_terms has_accepted_submission_terms has_accepted_report_change_terms].each do |element|
        expect(result.failure.detect{|msg| msg.scan(/#{element}/)}).to be_present
      end
    end
  end

  describe "when all applicants applying coverage" do
    before do
      allow(application).to receive(:relationships_complete?).and_return(true)
      allow(subject).to receive(:notify).and_return(true)
      set_terms_on_application
      application.submit!
      create_elibility_determinations
      application.applicants.each{|applicant| applicant.update(eligibility_determination_id: application.eligibility_determinations.first.id)}
    end

    it 'should return success' do
      result = subject.call(application_id: application.id)
      expect(result).to be_a(Dry::Monads::Result::Success)

      doc = Nokogiri::XML(result.success)
      doc.xpath("//xmlns:is_coverage_applicant").each do |element|
        expect(element.text).to eq 'true'
      end
    end
  end

  describe "when some applicants not applying coverage" do

    let(:conditional_elements) {
      %w[immigration_information is_incarcerated has_insurance is_self_attested_blind is_veteran has_daily_living_help has_bill_pay_3_month_help]
    }
    before do
      allow(application).to receive(:relationships_complete?).and_return(true)
      allow(subject).to receive(:notify).and_return(true)
      set_terms_on_application
      application.submit!
      create_elibility_determinations
      application.applicants[0..1].each{|applicant| applicant.update_attributes(eligibility_determination_id: application.eligibility_determinations.first.id, is_applying_coverage: true)}
      application.applicants[2..-1].each{|applicant| applicant.update_attributes(eligibility_determination_id: application.eligibility_determinations.first.id, is_applying_coverage: false)}
    end

    it 'should return success with skipped elements' do
      result = subject.call(application_id: application.id)
      expect(result).to be_a(Dry::Monads::Result::Success)

      doc = Nokogiri::XML(result.success)
      doc.xpath("//xmlns:assistance_tax_household_member").each do |element|
        if element.search('is_coverage_applicant').text == 'true'
          conditional_elements.each{|name| expect(element.search(name)).to be_present }
        else
          conditional_elements.each{|name| expect(element.search(name)).to be_empty }
        end
      end
    end
  end
end