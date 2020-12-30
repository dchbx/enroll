# frozen_string_literal: true

require 'rails_helper'

describe 'daily_eligibility_determination_change_report' do
  before do
    DatabaseCleaner.clean
  end

  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }

  before :each do
    @consumer_role = person.consumer_role
    @vlp_doc = @consumer_role.vlp_documents.first
    @vlp_doc.update_attributes!(subject: 'Other (With I-94)')
    invoke_fix_vlp_document_other_i94
    @file_content = CSV.read("#{Rails.root}/other_i94_vlp_issue_people_with_consumer_aasm_state.csv")
  end

  it 'should update the vlp document subject' do
    @vlp_doc.reload
    expect(@vlp_doc.subject).to eq('Other (With I-94 Number)')
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

  it 'should match with the consumer_role aasm_state' do
    expect(@file_content[1][3]).to eq(@consumer_role.aasm_state)
  end

  it 'should match with the vlp_document id' do
    expect(@file_content[1][4]).to eq(@vlp_doc.id.to_s)
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/other_i94_vlp_issue_people_with_consumer_aasm_state.csv")
  end
end

def invoke_fix_vlp_document_other_i94
  load File.join(Rails.root, 'script/fix_vlp_document_other_i94.rb')
end
