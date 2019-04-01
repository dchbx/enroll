require "rails_helper"

describe "ProjectedEligibilityNotice_2" do
  let!(:person) {FactoryGirl.create(:person, :with_consumer_role, first_name: "Test", last_name: "Data", dob: "02/12/1981", hbx_id: "a16f4029916445fcab3dbc44bb7aadd0") }
  let!(:user) {FactoryGirl.create(:user, person: person) }
  let!(:family100) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}

  it "should create projected_eligibility_notice_aqhp report" do
    invoke_pre_script
    data = file_reader
    expect(data[0].present?).to eq true
    expect(data[1].present?).to eq true
    expect(data[1][1]).to eq(person.hbx_id.to_s)
    expect(data[1][2]).to eq(person.full_name)
  end

  after :all do
    FileUtils.rm_rf(Dir.glob(File.join(Rails.root, 'spec/test_data/notices/projected_eligibility_notice_aqhp_report_*.csv')))
  end
end

private

def file_reader
  files = Dir.glob(File.join(Rails.root, 'spec/test_data/notices/projected_eligibility_notice_aqhp_report_*.csv'))
  CSV.read files.first
end

def invoke_pre_script
  eligibility_script = File.join(Rails.root, "script/projected_eligibility_notice_2.rb")
  load eligibility_script
end