require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "primary_family_members_data_with_e_case_id")

describe PrimaryFamilyMembersDataWithECaseId do

  let(:given_task_name) { "with_e_case_id" }
  subject { PrimaryFamilyMembersDataWithECaseId.new(given_task_name, double(:current_scope => nil)) }
  let(:person1) {FactoryGirl.create(:person,
                                    :with_consumer_role,
                                    first_name: "f_name1",
                                    last_name:"l_name1")}
  
    let(:person2) {FactoryGirl.create(:person,
                                    :with_employee_role,
                                    first_name: "f_name2",
                                    last_name:"l_name2")}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person1)}
    let(:dependent) { FactoryGirl.create(:family_member, :person => person2, :family => family )}

  describe "correct data input" do
     it "has the given task name" do
       expect(subject.name).to eql given_task_name
     end

     it "should have correct data" do
      expect(family.e_case_id).to be_truthy
      expect(family.primary_family_member).to be_truthy
      expect(family.dependents).to be_truthy
     end
    end
    
   shared_examples_for "returns csv file list of families with e_case_id" do |field_name, result|
     before :each do
       subject.migrate
       @file = "#{Rails.root}/public/primary_family_members_data_with_e_case_id.csv"
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
end
