require "rails_helper"

describe ::Importers::ConversionEmployerPlanYearSet, dbclean: :after_each do
  let(:out_stream) { StringIO.new }
  let(:employer_record) { instance_double("::Importers::ConversionEmployerPlanYearCreate", :save => record_save_result, :errors => record_errors, :warnings => record_warnings) }
  let(:record_errors) { { } }
  let(:record_warnings) { { } }
  let(:default_plan_year_start) { Date.new(2015, 3, 1) }

  subject { ::Importers::ConversionEmployerPlanYearSet.new(file_name, out_stream, default_plan_year_start) }
  before :each do
    allow(::Importers::ConversionEmployerPlanYearCreate).to receive(:new).with(employer_data).and_return(employer_record)
    subject.import!
    out_stream.rewind
  end


  describe "provided a file in xlsx format" do
    let(:file_name) { File.join(Rails.root, "spec", "test_data", "conversion_employers", "sample_conversion_employers.xlsx") }

    let(:employer_data) do
      {:action=>"Add", :default_plan_year_start=> default_plan_year_start, :fein=>"931100000", :enrolled_employee_count=>"14", :new_coverage_policy=>"Date of Hire equal to Effective Date", :carrier=>"United Healtcare", :plan_selection=>"Single Plan from Carrier", :single_plan_hios_id=>"41842DC0010068-01", :coverage_start=>"07/01/2016"}
    end


    let(:base_output_result) do
      "Action,FEIN,Doing Business As,Legal Name,Physical Address 1,Physical Address 2,City,State,Zip,County,Mailing Address 1,Mailing Address 2,City,State,Zip,Contact First Name,Contact Last Name,Contact Email,Contact Phone,Enrolled Employee Count,New Hire Coverage Policy,Contact Address 1,Contact Address 2,City,State,Zip,Broker Name,Broker NPN,TPA Name,TPA FEIN,Coverage Start Date,Carrier Selected,Plan Selection Category,Plan Name,Plan HIOS Id,Most Enrollees - Plan Name,Most Enrollees - Plan HIOS Id,Reference Plan - Name,Reference Plan - HIOS Id,Employer Contribution -  Employee,Employer Contribution - Spouse,Employer Contribution - Domestic Partner,Employer Contribution - Child under 26,Employer Contribution - Child over 26,Employer Contribution - Disabled child over 26,Import Status,Import Details\nAdd,931100000,AGA DBA,AGA LEGAL,799 9TH STREET NW,7TH FLR,Washington,DC,20001.0,County,\"\",\"\",\"\",\"\",\"\",THE,CONTACT,THECONTACT@AGA.COM,2025552675,14.0,Date of Hire equal to Effective Date,799 9TH STREET NW,7TH FLR,Washington,DC,20001.0,THE BROKER   ,8262800  ,\"\",\"\",07/01/2016,United Healtcare,Single Plan from Carrier,Choice Plus Insurance/0/5000,41842DC0010068-01,\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\""
    end

    describe "with a valid employer record" do
      let(:record_save_result) { true }

      it "should write the initial data and the results to the output stream" do
        expect(out_stream.string).to eql(base_output_result + ",imported,\"\"\n")
      end
    end

    describe "with an invalid employer record" do
      let(:record_save_result) { false }
      let(:record_errors) { {"some_errors" => "about_a_thing" } }

      it "should write the initial data and the results to the output stream" do
        expect(out_stream.string).to eql(base_output_result + ",\"[\"\"import failed\"\", \"\"{\\\"\"some_errors\\\"\":\\\"\"about_a_thing\\\"\"}\"\"]\"\n")
      end
    end

    describe "with a valid employer record, with warnings" do
      let(:record_save_result) { true }
      let(:record_warnings) { {"some_warnings" => "about_a_thing" } }

      it "should write the initial data and the results to the output stream" do
        expect(out_stream.string).to eql(base_output_result + ",imported with warnings,\"{\"\"some_warnings\"\":\"\"about_a_thing\"\"}\"\n")
      end
    end
  end

  describe "provided a file in csv format" do
    let(:file_name) { File.join(Rails.root, "spec", "test_data", "conversion_employers", "sample_conversion_employers.csv") }

    let(:employer_data) do
      {:action=>"Add", :default_plan_year_start=> default_plan_year_start, :fein=>"521782000", :enrolled_employee_count=>"3", :carrier=>"CareFirst BlueCross BlueShield", :plan_selection=>"Single Plan from Carrier",:most_common_hios_id=>"86052DC0480005-01",:single_plan_hios_id =>"86052DC0480005-01" , :coverage_start=>"07/01/2016"}
    end

    let(:base_output_result) do
      "Action,FEIN,Doing Business As,Legal Name,Physical Address 1,Physical Address 2,City,State,Zip,County,Mailing Address 1,Mailing Address 2,City,State,Zip,Contact First Name,Contact Last Name,Contact Email,Contact Phone,Enrolled Employee Count,New Hire Coverage Policy,Contact Address 1,Contact Address 2,City,State,Zip,Broker Name,Broker NPN,TPA Name,TPA FEIN,Coverage Start Date,Carrier Selected,Plan Selection Category,Plan Name,Plan HIOS Id,Most Enrollees - Plan Name,Most Enrollees - Plan HIOS Id,Reference Plan - Name,Reference Plan - HIOS Id,Employer Contribution -  Employee,Employer Contribution - Spouse,Employer Contribution - Domestic Partner,Employer Contribution - Child under 26,Employer Contribution - Child over 26,Employer Contribution - Disabled child over 26,Import Status,Import Details\nAdd,521782000,MCP DBA,MCP LEGAL,3001 P Street N.W., ,Washington,DC,20007,County,3001 P Street N.W., ,Washington,DC,20007,The,Contact,thecontact@mcp.com,2025554100,3, ,3001 P Street N.W., ,Washington,DC,20007,The Broker,629000, , ,07/01/2016,CareFirst BlueCross BlueShield,Single Plan from Carrier ,BC HMO Ref  500 Gold Trad Dental Drug,86052DC0480005-01,BC HMO Ref  500 Gold Trad Dental Drug,86052DC0480005-01,\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\""
    end

    describe "with a valid employer record" do
      let(:record_save_result) { true }

      it "should write the initial data and the results to the output stream" do
        expect(out_stream.string).to eql(base_output_result + ",imported,\"\"\n")
      end
    end

    describe "with an invalid employer record" do
      let(:record_save_result) { false }
      let(:record_errors) { {"some_errors" => "about_a_thing" } }

      it "should write the initial data and the results to the output stream" do
        expect(out_stream.string).to eql(base_output_result + ",\"[\"\"import failed\"\", \"\"{\\\"\"some_errors\\\"\":\\\"\"about_a_thing\\\"\"}\"\"]\"\n")
      end
    end

    describe "with a valid employer record, with warnings" do
      let(:record_save_result) { true }
      let(:record_warnings) { {"some_warnings" => "about_a_thing" } }

      it "should write the initial data and the results to the output stream" do
        expect(out_stream.string).to eql(base_output_result + ",imported with warnings,\"{\"\"some_warnings\"\":\"\"about_a_thing\"\"}\"\n")
      end
    end
  end

end
