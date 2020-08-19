require 'rails_helper'

describe "Haven person demographics parser" do
  let(:class_name) {self.name.demodulize}
  include_examples "haven parser examples", class_name

  context "verified members" do
    it 'should get ssn' do
      subject.each_with_index do |sub, index|
        if ssn.text.present?
          expect(sub.ssn).to eq ssn[index].text.strip
        else
          expect(sub.ssn).to eq ""
        end
      end
    end

    it 'should get sex' do
      subject.each_with_index do |sub, index|
        if sex.text.present?
          expect(sub.sex).to eq sex[index].text.strip
        else
          expect(sub.sex).to eq ""
        end
      end
    end

    it 'should get birth date' do
      subject.each_with_index do |sub, index|
        if birth_date.text.present?
          expect(sub.birth_date).to eq birth_date[index].text.strip
        else
          expect(sub.birth_date).to eq ""
        end
      end
    end
  end
end
