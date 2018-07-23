require "rails_helper"

describe ::Importers::ConversionEmployeeSet do
  let(:out_stream) { StringIO.new }
  let(:employee_record) { instance_double("::Importers::ConversionEmployeeCreate", :save => record_save_result, :errors => record_errors, :warnings => record_warnings) }
  let(:record_errors) { { } }
  let(:record_warnings) { { } }
  let(:config) { YAML.load_file("#{Rails.root}/conversions.yml") }

  subject { ::Importers::ConversionEmployeeSet.new(file_name, out_stream, config["conversions"]["employee_date"], config["conversions"]["number_of_dependents"] ) }
  before :each do
    allow(::Importers::ConversionEmployeeAction).to receive(:new).with(employee_data).and_return(employee_record)
    subject.import!
    out_stream.rewind    
  end

  describe "provided a file in xlsx format" do
    let(:file_name) { File.join(Rails.root, "spec", "test_data", "conversion_employees", "sample_conversion_employees.xlsx") }

    let(:employee_data) do
      {:default_hire_date=> config["conversions"]["employee_date"], :action=>"Add", :employer_name=>"CCD Care Inc", :fein=>"202187000", :benefit_begin_date=>"07/01/2015", :subscriber_ssn=>"219000368", :subscriber_dob=>"06/14/1962", :subscriber_gender=>"FEMALE", :subscriber_name_first=>"Totally", :subscriber_name_middle=>"An", :subscriber_name_last=>"Employee", :subscriber_address_1=>"5807 Cotton Tail Lane", :subscriber_city=>"Riverdale", :subscriber_state=>"MD", :subscriber_zip=>"20737", :dep_1_ssn=>"213000000", :dep_1_dob=>"08/02/2009", :dep_1_gender=>"MALE", :dep_1_name_first=>"Totally", :dep_1_name_middle=>"A", :dep_1_name_last=>"Kid", :dep_1_relationship=>"Child", :dep_2_dob=>"03/14/2011", :dep_2_gender=>"FEMALE", :dep_2_name_first=>"ThisIs", :dep_2_name_middle=>"Somebodys", :dep_2_name_last=>"Daughter", :dep_2_relationship=>"Child"}
    end

    let(:base_output_result) do
      "Action,Type of Enrollment,Market,Sponsor Name,FEIN,Broker Name,Broker NPN,Hire Date,Benefit Begin Date,Plan Name,QHP Id (ignore),CSR Info (ignore),CSR Variant (ignore),HIOS Id,(AUTO) Premium Total,Employer Contribution,(AUTO) Employee Responsible Amt,Subscriber SSN,Subscriber DOB,Subscriber Gender,Subscriber Premium,Subscriber First Name,Subscriber Middle Name,Subscriber Last Name,Subscriber Email,Subscriber Phone,Subscriber Address 1,Subscriber Address 2,Subscriber City,Subscriber State,Subscriber Zip,SELF (only one option),Dep1 SSN,Dep1 DOB,Dep1 Gender,Dep1 Premium,Dep1 First Name,Dep1 Middle Name,Dep1 Last Name,Dep1 Email,Dep1 Phone,Dep1 Address 1,Dep1 Address 2,Dep1 City,Dep1 State,Dep1 Zip,Dep1 Relationship,Dep2 SSN,Dep2 DOB,Dep2 Gender,Dep2 Premium,Dep2 First Name,Dep2 Middle Name,Dep2 Last Name,Dep2 Email,Dep2 Phone,Dep2 Address 1,Dep2 Address 2,Dep2 City,Dep2 State,Dep2 Zip,Dep2 Relationship,Dep3 SSN,Dep3 DOB,Dep3 Gender,Dep3 Premium,Dep3 First Name,Dep3 Middle Name,Dep3 Last Name,Dep3 Email,Dep3 Phone,Dep3 Address 1,Dep3 Address 2,Dep3 City,Dep3 State,Dep3 Zip,Dep3 Relationship,Dep4 SSN,Dep4 DOB,Dep4 Gender,Dep4 Premium,Dep4 First Name,Dep4 Middle Name,Dep4 Last Name,Dep4 Email,Dep4 Phone,Dep4 Address 1,Dep4 Address 2,Dep4 City,Dep4 State,Dep4 Zip,Dep4 Relationship,Dep5 SSN,Dep5 DOB,Dep5 Gender,Dep5 Premium,Dep5 First Name,Dep5 Middle Name,Dep5 Last Name,Dep5 Email,Dep5 Phone,Dep5 Address 1,Dep5 Address 2,Dep5 City,Dep5 State,Dep5 Zip,Dep5 Relationship,Dep6 SSN,Dep6 DOB,Dep6 Gender,Dep6 Premium,Dep6 First Name,Dep6 Middle Name,Dep6 Last Name,Dep6 Email,Dep6 Phone,Dep6 Address 1,Dep6 Address 2,Dep6 City,Dep6 State,Dep6 Zip,Dep6 Relationship,Dep7 SSN,Dep7 DOB,Dep7 Gender,Dep7 Premium,Dep7 First Name,Dep7 Middle Name,Dep7 Last Name,Dep7 Email,Dep7 Phone,Dep7 Address 1,Dep7 Address 2,Dep7 City,Dep7 State,Dep7 Zip,Dep7 Relationship,Dep8 SSN,Dep8 DOB,Dep8 Gender,Dep8 Premium,Dep8 First Name,Dep8 Middle Name,Dep8 Last Name,Dep8 Email,Dep8 Phone,Dep8 Address 1,Dep8 Address 2,Dep8 City,Dep8 State,Dep8 Zip,Dep8 Relationship,Import Status,Import Details\nAdd,New Enrollment,Shop,CCD Care Inc,202187000.0,\"\",\"\",\"\",07/01/2015,Medical Fully Insured Exchange,\"\",\"\",\"\",86052DC0480005,830.75,\"\",\"\",219000368.0,06/14/1962,FEMALE,344.57,Totally,An,Employee, , ,5807 Cotton Tail Lane, ,Riverdale,MD,20737.0,Self ,213000000.0,08/02/2009,MALE,486.18,Totally,A,Kid,\"\",\"\",\"\",\"\",\"\",\"\",\"\",Child, ,03/14/2011,FEMALE,\"\",ThisIs,Somebodys,Daughter,\"\",\"\",\"\",\"\",\"\",\"\",\"\",Child,\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\""
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
    let(:file_name) { File.join(Rails.root, "spec", "test_data", "conversion_employees", "sample_conversion_employees.csv") }

    let(:employee_data) do
      {:default_hire_date=>config["conversions"]["employee_date"], :action=>"Add", :employer_name=>"CCD Care Inc", :fein=>"202187000", :benefit_begin_date=>"07/01/2015", :subscriber_ssn=>"219000368", :subscriber_dob=>"06/14/1962", :subscriber_gender=>"FEMALE", :subscriber_name_first=>"Totally", :subscriber_name_middle=>"An", :subscriber_name_last=>"Employee", :subscriber_address_1=>"5807 Cotton Tail Lane", :subscriber_city=>"Riverdale", :subscriber_state=>"MD", :subscriber_zip=>"20737", :dep_1_ssn=>"213000000", :dep_1_dob=>"08/02/2009", :dep_1_gender=>"MALE", :dep_1_name_first=>"Totally", :dep_1_name_middle=>"A", :dep_1_name_last=>"Kid", :dep_1_relationship=>"Child", :dep_2_dob=>"03/14/2011", :dep_2_gender=>"FEMALE", :dep_2_name_first=>"ThisIs", :dep_2_name_middle=>"Somebodys", :dep_2_name_last=>"Daughter", :dep_2_relationship=>"Child"}
    end

    let(:base_output_result) do
      "Action,Type of Enrollment,Market,Sponsor Name,FEIN,Broker Name,Broker NPN,Hire Date,Benefit Begin Date,Plan Name,QHP Id (ignore),CSR Info (ignore),CSR Variant (ignore),HIOS Id,(AUTO) Premium Total,Employer Contribution,(AUTO) Employee Responsible Amt,Subscriber SSN,Subscriber DOB,Subscriber Gender,Subscriber Premium,Subscriber First Name,Subscriber Middle Name,Subscriber Last Name,Subscriber Email,Subscriber Phone,Subscriber Address 1,Subscriber Address 2,Subscriber City,Subscriber State,Subscriber Zip,SELF (only one option),Dep1 SSN,Dep1 DOB,Dep1 Gender,Dep1 Premium,Dep1 First Name,Dep1 Middle Name,Dep1 Last Name,Dep1 Email,Dep1 Phone,Dep1 Address 1,Dep1 Address 2,Dep1 City,Dep1 State,Dep1 Zip,Dep1 Relationship,Dep2 SSN,Dep2 DOB,Dep2 Gender,Dep2 Premium,Dep2 First Name,Dep2 Middle Name,Dep2 Last Name,Dep2 Email,Dep2 Phone,Dep2 Address 1,Dep2 Address 2,Dep2 City,Dep2 State,Dep2 Zip,Dep2 Relationship,Dep3 SSN,Dep3 DOB,Dep3 Gender,Dep3 Premium,Dep3 First Name,Dep3 Middle Name,Dep3 Last Name,Dep3 Email,Dep3 Phone,Dep3 Address 1,Dep3 Address 2,Dep3 City,Dep3 State,Dep3 Zip,Dep3 Relationship,Dep4 SSN,Dep4 DOB,Dep4 Gender,Dep4 Premium,Dep4 First Name,Dep4 Middle Name,Dep4 Last Name,Dep4 Email,Dep4 Phone,Dep4 Address 1,Dep4 Address 2,Dep4 City,Dep4 State,Dep4 Zip,Dep4 Relationship,Dep5 SSN,Dep5 DOB,Dep5 Gender,Dep5 Premium,Dep5 First Name,Dep5 Middle Name,Dep5 Last Name,Dep5 Email,Dep5 Phone,Dep5 Address 1,Dep5 Address 2,Dep5 City,Dep5 State,Dep5 Zip,Dep5 Relationship,Dep6 SSN,Dep6 DOB,Dep6 Gender,Dep6 Premium,Dep6 First Name,Dep6 Middle Name,Dep6 Last Name,Dep6 Email,Dep6 Phone,Dep6 Address 1,Dep6 Address 2,Dep6 City,Dep6 State,Dep6 Zip,Dep6 Relationship,Dep7 SSN,Dep7 DOB,Dep7 Gender,Dep7 Premium,Dep7 First Name,Dep7 Middle Name,Dep7 Last Name,Dep7 Email,Dep7 Phone,Dep7 Address 1,Dep7 Address 2,Dep7 City,Dep7 State,Dep7 Zip,Dep7 Relationship,Dep8 SSN,Dep8 DOB,Dep8 Gender,Dep8 Premium,Dep8 First Name,Dep8 Middle Name,Dep8 Last Name,Dep8 Email,Dep8 Phone,Dep8 Address 1,Dep8 Address 2,Dep8 City,Dep8 State,Dep8 Zip,Dep8 Relationship,Import Status,Import Details\nAdd,New Enrollment,Shop,CCD Care Inc,202187000,\"\",\"\",\"\",07/01/2015,Medical Fully Insured Exchange,\"\",\"\",\"\",86052DC0480005,830.7500,\"\",\"\",219000368,06/14/1962,FEMALE,344.5700,Totally,An,Employee, , ,5807 Cotton Tail Lane, ,Riverdale,MD,20737,Self ,213000000,08/02/2009,MALE,486.1800,Totally,A,Kid,\"\",\"\",\"\",\"\",\"\",\"\",\"\",Child, ,03/14/2011,FEMALE,\"\",ThisIs,Somebodys,Daughter,\"\",\"\",\"\",\"\",\"\",\"\",\"\",Child,\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\""
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

describe ::Importers::ConversionEmployeeSet do
  describe "functional validation at the imported set level" do
    context "file contains more than one record for the same employee" do
      it "raises an error 'invalid file composition: more than one employee add or update per file not allowed"
    end
  end

  describe "persisting the imported set level" do
    context "and at least one record has a [:base] level error" do
      context "and the persistance flag is set to 'atomicity' (all or nothing)" do
        it "should not persist the set"
      end

      context "and the persistance flag is set to 'permissive'" do
        it "should persist all records that do not have a [:base] level error"
      end
    end

    context "and at least one record has only non-[:base] level errors" do
      context "and the persistance flag is set to 'atomicity' (all or nothing)" do
        it "should not persist the set"
      end

      context "and the persistance flag is set to 'permissive'" do
        it "should persist all records that don't have a [:base] error"
      end
    end

    context "and there are no errors" do
      it "should persist all records"
    end
  end
end