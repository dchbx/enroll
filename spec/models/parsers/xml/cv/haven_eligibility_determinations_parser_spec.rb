require 'rails_helper'

describe 'HavenEligibilityDeterminationsParser' do
  let(:class_name) {self.name.demodulize}
  include_examples "haven parser examples", class_name

  context "verified members" do
    it 'should get id' do
      subject.each_with_index do |sub, index|
        expect(sub.id).to eq eligibility_determination_id[index].text.strip
      end
    end

    it 'should get maximum_aptc' do
      subject.each_with_index do |sub, index|
        expect(sub.maximum_aptc).to eq maximum_aptc[index].text.strip
      end
    end

    it 'should get csr_percent' do
      subject.each_with_index do |sub, index|
        expect(sub.csr_percent).to eq csr_percent[index].text.strip
      end
    end

    it 'should get aptc_csr_annual_household_income' do
      subject.each_with_index do |sub, index|
        expect(sub.aptc_csr_annual_household_income).to eq aptc_csr_annual_household_income[index].text.strip
      end
    end

    it 'should get determination_date' do
      subject.each_with_index do |sub, index|
        expect(sub.determination_date.to_s).to eq determination_date[index].text.strip.to_date.to_s
      end
    end

    it 'should get aptc_annual_income_limit' do
      subject.each_with_index do |sub, index|
        expect(sub.aptc_annual_income_limit).to eq aptc_annual_income_limit[index].text
      end
    end

    it 'should get csr_annual_income_limit' do
      subject.each_with_index do |sub, index|
        expect(sub.csr_annual_income_limit).to eq csr_annual_income_limit[index].text
      end
    end

    it 'should get created_at' do
      subject.each_with_index do |sub, index|
        expect(sub.created_at.to_s).to eq eligibility_determination_created_at[index].text.strip.to_datetime.to_s
      end
    end
  end
end