require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "inverse_relations")

describe InverseRelations do 
  let(:given_task_name) { "with_e_case_id" }
  subject { InverseRelations.new(given_task_name, double(:current_scope => nil)) }
  let(:person1) {FactoryGirl.create(:person,
                                     first_name: "f_name1",
                                     last_name:"l_name1",
                                     dob: "1993-06-03",
                                     )}
   
   let(:child1) {FactoryGirl.create(:person,
                                     first_name: "f_name2",
                                     last_name:"l_name2",
                                     dob: "1965-09-05",)}
  

    let!(:person) do
      p = FactoryGirl.create(:person,
                                     first_name: "f_name1",
                                     last_name:"l_name1",
                                     dob: "1993-06-03",
                                     )
      p.person_relationships.build(relative: child1, kind: "child")
      p.save
      p
    end
   let(:family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person)}
   let(:child) { FactoryGirl.create(:family_member, :person => child1, :family => family )}

    describe "correct data input" do
      it "should have correct data" do
        child.person.reload
        expect(family.primary_family_member).to be_truthy
        expect(family.dependents).to be_truthy
      end
    end

    shared_examples_for "returns csv file list with inverse relationships" do |field_name, result|
      before :each do
        subject.migrate
        @file = "#{Rails.root}/public/inverse_relations.csv"
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
    it_behaves_like "returns csv file list with inverse relationships", 'Dependent_First_Name', "f_name2"
end