require "rails_helper"

describe "ProjectedEligibilityNotice_1" do
  before do
    DatabaseCleaner.clean
  end

  let!(:person) {FactoryBot.create(:person, :with_consumer_role, first_name: "Test", last_name: "Data", hbx_id: "91091f87b17d4f91af5fd1646d8acf66") }
  let!(:user) {FactoryBot.create(:user, person: person) }
  let!(:family100) {FactoryBot.create(:family, :with_primary_family_member, person: person, id: "5c6594605f326d004f000060")}
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, household: family100.active_household, family: family100, kind: "individual", hbx_id: "7894416f079343918d1333771c222879")
  end

  it "should create projected_eligibility_notice_uqhp report" do
    invoke_pre_script1
    data = file_reader1
    expect(data[0].present?).to eq true
    expect(data[1].present?).to eq true
    expect(data[1][0]).to eq(family100.id.to_s)
    expect(data[1][1]).to eq(person.hbx_id.to_s)
    expect(data[1][2]).to eq(person.full_name)
  end

  after :all do
    FileUtils.rm_rf(Dir.glob(File.join(Rails.root, 'spec/test_data/notices/projected_eligibility_notice_uqhp_report_*.csv')))
  end
end

private

def file_reader1
  files = Dir.glob(File.join(Rails.root, 'spec/test_data/notices/projected_eligibility_notice_uqhp_report_*.csv'))
  CSV.read files.first
end

def invoke_pre_script1
  eligibility_script1 = File.join(Rails.root, "script/projected_eligibility_notice_1.rb")
  load eligibility_script1
end