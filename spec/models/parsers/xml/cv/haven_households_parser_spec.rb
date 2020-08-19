require 'rails_helper'

describe "haven households parser" do
  let(:class_name) {self.name.demodulize}
  include_examples "haven parser examples", class_name

  context "verified members" do
    it 'should get id' do
      subject.each_with_index do |sub, index|
        if household_id.text.present?
          expect(sub.id).to eq household_id[index].text.strip
        else
          expect(sub.id).to eq nil
        end
      end
    end

    it 'should get irs_group_id' do
      subject.each_with_index do |sub, index|
        if irs_group_id.text.present?
          expect(sub.irs_group_id).to eq irs_group_id[index].text.strip
        else
          expect(sub.irs_group_id).to eq ""
        end
      end
    end

    it 'should get start_date' do
      subject.each_with_index do |sub, index|
        if start_date.text.present?
          expect(sub.start_date.to_s).to eq start_date[index].text.to_date.to_s
        else
          expect(sub.start_date).to eq nil
        end
      end
    end

    it 'should get tax_households' do
      subject.each_with_index do |sub, index|
        expect(sub.tax_households.class).to eq Array
      end
    end
  end
end