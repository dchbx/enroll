require 'rails_helper'

RSpec.describe "events/census_employee/employer_response.xml.haml.erb" do
  include AcapiVocabularySpecHelpers

  before(:all) do
    download_vocabularies
  end

  context "single census employee" do
    let(:census_employees) { ep = FactoryGirl.create(:employer_profile);
                             ce = FactoryGirl.create(:census_employee, employer_profile_id: ep.id);
                            [ce] }

    describe "employer with one census employees" do

      before(:each) do
        render :template => "events/census_employee/employer_response", :locals => {:census_employees => census_employees}
      end

      it "generates valid xml" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end
    end

    context "census employee has dependents" do
      let(:census_dependent) { FactoryGirl.build(:census_dependent) }
      let(:census_dependent2) { FactoryGirl.build(:census_dependent, employee_relationship: 'child_under_26') }

      before(:each) do
        census_employees.first.census_dependents = [census_dependent, census_dependent2]
        census_employees.first.save
        render :template => "events/census_employee/employer_response", :locals => {:census_employees => census_employees}
        @doc = Nokogiri::XML(rendered)
        @doc.remove_namespaces!
      end

      it "generates valid xml" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end

      it "adds 2 dependents to xml" do
        expect(@doc.xpath("//employers/employer/employer_profile/employer_census_families/employer_census_family/dependents/dependent").count).to eq 2
      end
    end
  end

  context "multiple census employees under one employer" do
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }

    let(:census_employees) { [FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id),
                              FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id)]}

    describe "employer with two census employees" do

      before(:each) do
        render :template => "events/census_employee/employer_response", :locals => {:census_employees => census_employees}
        @doc = Nokogiri::XML(rendered)
        @doc.remove_namespaces!
      end

      it "generates valid xml" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end

      it "has one employer" do
        expect(@doc.xpath("//employers/employer").count).to eq 1
      end

      it "has two census_employees" do
        expect(@doc.xpath("//employers/employer/employer_profile/employer_census_families/employer_census_family").count).to eq 2
      end
    end
  end

end