# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/haven_parser_shared_examples.rb"

RSpec.describe 'person demographics parser' do
  class_name = self.name.demodulize
  include_examples :haven_parser_examples, class_name

  context 'verified members' do
    it 'should get ssn' do
      subject.each_with_index do |sub, index|
        if ssn.text.present?
          expect(sub.ssn).to eq ssn[index].text.strip
        else
          expect(sub.ssn).to eq ''
        end
      end
    end

    it 'should get sex' do
      subject.each_with_index do |sub, index|
        if sex.text.present?
          expect(sub.sex).to eq sex[index].text.strip
        else
          expect(sub.sex).to eq ''
        end
      end
    end

    it 'should get birth date' do
      subject.each_with_index do |sub, index|
        if birth_date.text.present?
          expect(sub.birth_date).to eq birth_date[index].text.strip
        else
          expect(sub.birth_date).to eq ''
        end
      end
    end
  end
end
