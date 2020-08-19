require 'rails_helper'

describe 'Haven tax households parser' do
  let(:class_name) {self.name.demodulize}
  include_examples "haven parser examples", class_name

  context "verified members" do
    it 'should get hbx_assigned_id' do
      subject.each_with_index do |sub, index|
        expect(sub.hbx_assigned_id).to eq hbx_assigned_id[index].text.strip
      end
    end

    it 'should get primary_applicant_id' do
      subject.each_with_index do |sub, index|
        expect(sub.primary_applicant_id).to eq primary_applicant_id[index].text.strip
      end
    end

    it 'should get tax_household_members' do
      subject.each_with_index do |sub, index|
        expect(sub.tax_household_members.class).to eq Array
      end
    end

    it 'should get eligibility_determinations' do
      subject.each_with_index do |sub, index|
        expect(sub.eligibility_determinations.class).to eq Array
      end
    end

    it 'should get start_date' do
      subject.each_with_index do |sub, index|
        expect(sub.start_date.to_s).to eq start_date[index].text.to_date.to_s
      end
    end
  end
end