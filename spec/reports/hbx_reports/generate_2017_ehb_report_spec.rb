require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "generate_2017_ehb_report")

describe Generate2017EhbReport do

  let(:given_task_name) { "generate_2017_ehb_report" }
  let(:person) {FactoryGirl.create(:person,
                                    :with_consumer_role,
                                    first_name: "F_name1",
                                    last_name:"L_name1")}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person)}
  let(:plan){FactoryGirl.create(:plan, :ehb => 0.9945)}
  let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,
                                             household: family.active_household,
                                             effective_on: Date.parse("2017-1-1"),
                                             plan: plan,
                                             applied_aptc_amount: 550.98
                                             )}
  subject { Generate2017EhbReport.new(given_task_name, double(:current_scope => nil)) }

  describe "correct data input" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end

    it "has the families with hbx_enrollments and correct states" do
      expect(family.primary_family_member.person.hbx_id).to be_truthy
      expect(hbx_enrollment.hbx_id).to be_truthy
    end
  end

  shared_examples_for "returns csv file list of hbx_ids with enrollment hbx_ids" do |field_name, result|
    before :each do
      subject.migrate
      @file = "#{Rails.root}/hbx_report/generate_2017_ehb_report.csv"
    end

    it "check the records included in file" do
      file_context = CSV.read(@file)
      expect(file_context.size).to be > 1
    end

    it "returns correct #{field_name} in csv file" do
      CSV.foreach(@file, :headers => true) do |csv_obj|
        expect(csv_obj[field_name]).to eq result
      end
    end
  end

  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}//hbx_report"])
  end
end