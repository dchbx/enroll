# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/haven_parser_shared_examples.rb"

RSpec.describe 'TaxHouseholdMembersParser' do
  class_name = self.name.demodulize
  include_examples :haven_parser_examples, class_name

  context 'verified members' do
    it 'should get hbx_assigned_id' do
      subject.each_with_index do |sub, index|
        expect(sub.id).to eq tax_household_member_id[index].text.strip
      end
    end

    it 'should get person_id' do
      subject.each_with_index do |sub, index|
        expect(sub.person_id).to eq person_id[index].text.strip
      end
    end

    it 'should get person_surname' do
      subject.each_with_index do |sub, index|
        expect(sub.person_surname).to eq person_surname[index].text.strip
      end
    end

    it 'should get person_given_name' do
      subject.each_with_index do |sub, index|
        expect(sub.person_given_name).to eq person_given_name[index].text.strip
      end
    end

    it 'should get is_consent_applicant' do
      subject.each_with_index do |sub, index|
        expect(sub.is_consent_applicant.to_s).to eq is_consent_applicant[index].text.strip
      end
    end
  end
end