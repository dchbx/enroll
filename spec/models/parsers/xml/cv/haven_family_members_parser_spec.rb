require 'rails_helper'

describe "HavenFamilyMembersParser" do
  let(:class_name) {self.name.demodulize}
  include_examples "haven parser examples", class_name

  context "verified members" do
    it 'should get id' do
      subject.each_with_index do |sub, index|
        if family_member_id.text.present?
        expect(sub.id).to eq family_member_id[index].text.strip
        else
          expect(sub.family_member_id.present?.to_s).to eq ""
        end
      end
    end

    it 'should get person' do
      subject.each_with_index do |sub, index|
        expect(sub.person).to be_instance_of(Parsers::Xml::Cv::HavenPersonParser)
      end
    end

    it 'should get person_demographics' do
      subject.each_with_index do |sub, index|
        expect(sub.person_demographics).to be_instance_of(Parsers::Xml::Cv::HavenPersonDemographicsParser)
      end
    end

    it 'should check is_primary_applicant present' do
      subject.each_with_index do |sub, index|
        if is_primary_applicant.text.present?
          expect(sub.is_primary_applicant.present?.to_s).to eq is_primary_applicant[index].text.strip
        else
          expect(sub.is_primary_applicant.present?.to_s).to eq ""
        end
      end
    end

    it 'should check is_coverage_applicant present' do
      subject.each_with_index do |sub, index|
        if is_coverage_applicant.text.present?
          expect(sub.is_coverage_applicant.present?.to_s).to eq is_coverage_applicant[index].text.strip
        else
          expect(sub.is_coverage_applicant.present?.to_s).to eq ""
        end
      end
    end

    it 'should check is_without_assistance present' do
      subject.each_with_index do |sub, index|
        if is_without_assistance.text.present?
          expect(sub.is_without_assistance.present?.to_s).to eq is_without_assistance[index].text.strip
        else
          expect(sub.is_without_assistance.present?.to_s).to eq ""
        end
      end
    end

    it 'should check insurance_assistance_eligible present' do
      subject.each_with_index do |sub, index|
        if is_insurance_assistance_eligible.text.present?
          expect(sub.is_insurance_assistance_eligible.present?.to_s).to eq is_insurance_assistance_eligible[index].text.strip
        else
          expect(sub.is_insurance_assistance_eligible.present?.to_s).to eq ""
        end
      end
    end

    it 'should check medicaid_chip_eligible present' do
      subject.each_with_index do |sub, index|
        if is_medicaid_chip_eligible.text.present?
          expect(sub.is_medicaid_chip_eligible.present?.to_s).to eq is_medicaid_chip_eligible[index].text.strip
        else
          expect(sub.is_medicaid_chip_eligible.present?.to_s).to eq ""
        end
      end
    end

    it 'should check non_magi_medicaid_eligible present' do
      subject.each_with_index do |sub, index|
        if is_non_magi_medicaid_eligible.text.present?
          expect(sub.is_non_magi_medicaid_eligible.present?.to_s).to eq is_non_magi_medicaid_eligible[index].text.strip
        else
          expect(sub.is_non_magi_medicaid_eligible.present?.to_s).to eq ""
        end
      end
    end

    it 'should get magi_medicaid_monthly_household_income' do
      subject.each_with_index do |sub, index|
        if magi_medicaid_monthly_household_income.text.present?
          expect(sub.magi_medicaid_monthly_household_income.to_s).to eq magi_medicaid_monthly_household_income[index].text.strip
        else
          expect(sub.magi_medicaid_monthly_household_income.to_s).to eq ""
        end
      end
    end

    it 'should get magi_medicaid_monthly_income_limit' do
      subject.each_with_index do |sub, index|
        if magi_medicaid_monthly_income_limit.present?
          expect(sub.magi_medicaid_monthly_income_limit.to_s).to eq magi_medicaid_monthly_income_limit[index].text.strip
        else
          expect(sub.magi_medicaid_monthly_income_limit.to_s).to eq ""
        end
      end
    end

    it 'should get magi_as_percentage_of_fpl' do
      subject.each_with_index do |sub, index|
        if magi_as_percentage_of_fpl.text.present?
          expect(sub.magi_as_percentage_of_fpl.to_s).to eq magi_as_percentage_of_fpl[index].text.strip
        else
          expect(sub.magi_as_percentage_of_fpl.to_s).to eq ""
        end
      end
    end

    it 'should get magi_medicaid_category' do
      subject.each_with_index do |sub, index|
        expect(sub.magi_medicaid_category).to eq magi_medicaid_category[index].text.strip == "true"
      end
    end

    it 'should get medicaid_household_size' do
      subject.each_with_index do |sub, index|
        if medicaid_household_size.present?
          expect(sub.medicaid_household_size.to_s).to eq medicaid_household_size[index].text.strip
        else
          expect(sub.medicaid_household_size.to_s).to eq ""
        end
      end
    end

    it 'should get check totally_ineligible present' do
      subject.each_with_index do |sub, index|
        if is_totally_ineligible.text.present?
          expect(sub.is_totally_ineligible.present?.to_s).to eq is_totally_ineligible[index].text.strip
        else
          expect(sub.is_totally_ineligible.to_s).to eq ""
        end
      end
    end

    it 'should get check created_at present' do
      subject.each_with_index do |sub, index|
        if created_at.text.present?
          expect(sub.created_at).to eq created_at[index].text.strip
        else
          expect(sub.created_at.to_s).to eq ""
        end
      end
    end
  end
end
