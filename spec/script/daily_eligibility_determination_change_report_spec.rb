# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

describe 'daily_eligibility_determination_change_report' do
  before do
    DatabaseCleaner.clean
  end
  include_context 'setup one tax household with one ia member'

  before :each do
    tax_household.update_attributes!(created_at: Time.now.getlocal.prev_day)
    invoke_daily_eligibility_change_script
    @file_content = CSV.read("#{Rails.root}/daily_eligibility_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
  end

  it 'should add data to the file' do
    expect(@file_content.size).to be > 1
  end

  it 'should match with the first name' do
    expect(@file_content[1][0]).to eq(person.first_name)
  end

  it 'should match with the last name' do
    expect(@file_content[1][1]).to eq(person.last_name)
  end

  it 'should match with the hbx id' do
    expect(@file_content[1][2]).to eq(person.hbx_id)
  end

  it 'should match with the max aptc' do
    expect(@file_content[1][5]).to eq format('%.2f', eligibilty_determination.max_aptc.to_f)
  end

  it 'should match with the csr percent as integer' do
    expect(@file_content[1][7]).to eq(eligibilty_determination.csr_percent_as_integer.to_s)
  end

  it 'should return Curam as the source Curam' do
    expect(@file_content[1][10]).to eq('Curam')
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/daily_eligibility_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
    FileUtils.rm_rf("#{Rails.root}/daily_eligibility_report_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
  end
end

def invoke_daily_eligibility_change_script
  eligibility_change_script = File.join(Rails.root, "script/daily_eligibility_determination_change_report.rb")
  load eligibility_change_script
end
