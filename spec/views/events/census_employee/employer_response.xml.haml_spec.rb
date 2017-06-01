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

    describe "employer with no census employees" do

      before(:each) do
        render :template => "events/census_employee/employer_response", :locals => {:census_employees => census_employees}
      end

      it "generated valid xml" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end
    end
  end
end