require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "destroy_duplicates_with_enr")

describe DestroyDuplicatesWithEnr do

  let(:given_task_name) { "destroy_duplicates_with_enr" }
  let(:person1) {FactoryGirl.create(:person,
                                    :with_consumer_role,
                                    first_name: "F_name1",
                                    last_name:"L_name1")}
  let(:person2) {FactoryGirl.create(:person,
                                    :with_employee_role,
                                    first_name: "F_name2",
                                    last_name:"L_name2")}
  let(:person3) {FactoryGirl.create(:person,
                                    :with_employee_role,
                                    first_name: "F_name3",
                                    last_name:"L_name3")}
  subject { DestroyDuplicatesWithEnr.new(given_task_name, double(:current_scope => nil))}
  let!(:family) do
          f = family1
          f.family_members = [
            FactoryGirl.build(:family_member, family: f, person: person1, is_primary_applicant: true),
            FactoryGirl.build(:family_member, family: f, person: person2, is_primary_applicant: false),
            FactoryGirl.build(:family_member, :person => person2, :family => f, is_primary_applicant: false),
            FactoryGirl.build(:family_member, :person => person2, :family => f, is_primary_applicant: false)
           ]
         end
  let(:family1) { FactoryGirl.create(:family, :with_primary_family_member, :person => person1, is_active: true)}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family1.active_household, hbx_id: "0000", aasm_state: "coverage_selected", hbx_enrollment_members: [hbx_enrollment_member1, hbx_enrollment_member2])}
  let!(:hbx_enrollment_member1){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family1.family_members.second.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment_member2){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family1.family_members.second.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }

  describe "correct data input" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
    it "should destroy the duplicate family member" do
      expect(family1.family_members.count).to eql 4
      subject.migrate()
      family1.reload
      expect(family1.family_members.count).to eql 2
    end
    it "should destroy the duplicate hbx_enrollment member" do
      expect(family1.enrollments.first.hbx_enrollment_members.count).to eql 2
      subject.migrate()
      family1.reload
      family1.enrollments.first.reload
      expect(family1.enrollments.first.hbx_enrollment_members.count).to eql 1
    end
  end

  shared_examples_for "returns csv file list with duplicate family members" do |field_name, result|
    before :each do
      subject.migrate
      @file = "#{Rails.root}/hbx_report/destroy_duplicates_with_enr.csv"
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

  it_behaves_like "returns csv file list with duplicate family members", 'Enrollment_HBX_ID', "0000"
  it_behaves_like "returns csv file list with duplicate family members", 'Enrollment_aasm_state', "coverage_selected"

  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}//hbx_report"])
  end
end
