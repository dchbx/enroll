# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

describe FixCsrEligibilityKindsForEdsWithCsrPercentZero, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end
  include_context 'setup one tax household with one ia member'

  let(:given_task_name) { 'fix_csr_eligibility_kinds_for_eds_with_csr_percent_zero' }
  subject { FixCsrEligibilityKindsForEdsWithCsrPercentZero.new(given_task_name, double(:current_scope => nil)) }

  context 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  context 'valid curam determination' do
    before do
      eligibilty_determination.assign_attributes({csr_percent_as_integer: 0, csr_eligibility_kind: 'csr_100'})
      eligibilty_determination.save!(validate: false)
      subject.migrate
      eligibilty_determination.reload
      @file_content = CSV.read("#{Rails.root}/list_of_ed_objects_with_csr_0_1.csv")
    end

    it 'should add data to the file' do
      expect(@file_content.size).to be > 1
    end

    it 'should match with the person hbx_id' do
      expect(@file_content[1][0]).to eq(person.hbx_id)
    end

    it 'should match with the ed_object_id' do
      expect(@file_content[1][1]).to eq(eligibilty_determination.id.to_s)
    end

    it 'should match with the expected csr_percent_as_integer' do
      expect(@file_content[1][2]).to eq('0')
    end

    it 'should match with the expected csr_eligibility_kind' do
      expect(@file_content[1][3]).to eq('csr_0')
    end

    it 'should update the eligibilty_determination object' do
      expect(eligibilty_determination.csr_eligibility_kind).to eq('csr_0')
    end
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/list_of_ed_objects_with_csr_0_1.csv")
  end
end
