# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

describe FixEdSourceNonCuramCases do
  before do
    DatabaseCleaner.clean
  end
  include_context 'setup one tax household with one ia member'
  let(:year) { TimeKeeper.date_of_record.year }
  let(:given_task_name) { 'fix_ed_source_non_curam_cases' }
  subject { FixEdSourceNonCuramCases.new(given_task_name, double(:current_scope => nil)) }

  context 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  context 'ed creation using Create Eligibility tool' do
    context 'with source Admin_Script' do
      before :each do
        eligibilty_determination.assign_attributes({source: 'Admin_Script', created_at: Date.new(year, 12, 26)})
        eligibilty_determination.save!(validate: false)
        subject.migrate
        eligibilty_determination.reload
        @file_content = CSV.read("#{Rails.root}/list_of_ed_object_ids_for_non_curam_cases_1.csv")
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

      it 'should match with the expected source' do
        expect(@file_content[1][2]).to eq('Admin')
      end

      it 'should add e_pdc_id data' do
        expect(@file_content[1][3]).to be_truthy
      end

      it 'should return Admin as the source Create Eligibility tool' do
        expect(eligibilty_determination.source).to eq('Admin')
      end
    end

    context 'with source nil' do
      before :each do
        eligibilty_determination.assign_attributes({source: nil, created_at: Date.new(year, 12, 26)})
        eligibilty_determination.save!(validate: false)
        subject.migrate
        eligibilty_determination.reload
      end

      it 'should return Admin as the source Create Eligibility tool' do
        expect(eligibilty_determination.source).to eq('Admin')
      end
    end
  end

  context 'ed creation using Renewals' do
    let(:date) { [Date.new(year, 10, 31), Date.new(year, 11, 1)].sample }

    before :each do
      eligibilty_determination.assign_attributes({source: 'Admin_Script', created_at: date})
      eligibilty_determination.save!(validate: false)
      subject.migrate
      @file_content = CSV.read("#{Rails.root}/list_of_ed_object_ids_for_non_curam_cases_1.csv")
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

    it 'should return Renewals as the source Renewals' do
      expect(@file_content[1][2]).to eq('Renewals')
    end
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/list_of_ed_object_ids_for_non_curam_cases_1.csv")
  end
end
