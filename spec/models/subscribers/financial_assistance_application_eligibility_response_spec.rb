require "rails_helper"

describe Subscribers::FinancialAssistanceApplicationEligibilityResponse do
  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    allow_any_instance_of(FinancialAssistance::Application).to receive(:eligibility_determinations)
  end

  let(:hbx_profile_organization) { double("HbxProfile", benefit_sponsorship:  double(current_benefit_coverage_period: double(slcsp: Plan.new.id)))}
  let(:max_aptc){parser.households.select do |h| h.integrated_case_id == parser.integrated_case_id
                                          end.first.tax_households.select do |th| th.primary_applicant_id == parser.family_members.detect do |fm| fm.id == parser.primary_family_member_id
                                          end.id.split('#').last end.select do |th| th.id == th.primary_applicant_id && th.primary_applicant_id == parser.primary_family_member_id.split('#').last
                                          end.first.eligibility_determinations.max_by(&:determination_date).maximum_aptc }

  it "should subscribe to the correct event" do
    expect(Subscribers::FinancialAssistanceApplicationEligibilityResponse.subscription_details).to eq ["acapi.info.events.assistance_application.application_processed"]
  end

  before do
    allow(HbxProfile).to receive(:current_hbx).and_return(hbx_profile_organization)
    allow(hbx_profile_organization).to receive(:under_open_enrollment?).and_return(false)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "given a valid payload with a medicad member and get status 203" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "haven_eligibility_response_payloads", "verified_1_medicaid_member_1_thh_203_status.xml")) }

    context "update application as determined with status code" do
      let(:message) { { "body" => xml } }

      after do
        FinancialAssistance::Application.delete_all
        Family.delete_all
        TaxHousehold.delete_all
      end

      it "logs the failed to find the application error" do
        expect(subject).to receive(:log) do |arg1, arg2|
          expect(arg1).to eq message["body"]
          expect(arg2[:error_message]).to match(/ERROR: Failed to find the Application in XML/)
          expect(arg2[:severity]).to eq("critical")
        end
        subject.call(nil, nil, nil, nil, message)
      end

      context "with a valid application and return status" do

        let!(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let!(:person) { FactoryGirl.create(:person,:with_family) }
        # let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}",submitted_at: "2018-01-31 21:08:37 UTC", family: person.primary_family, aasm_state: "submitted")
        }
        let!(:message) { { "body" => "", "assistance_application_id" => application.hbx_id, "return_status" => 203 } }

        it "logs the failed to validate the XML against FAA XSD error" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to validate Eligibility Determination response XML/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "without person, with body, a valid application and return status" do
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }
        let(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 203 } }

        it "logs the failed to find primary person in xml error" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find primary person in xml/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "without primary person family, with primary person, body, a valid application and return status" do
        let(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 203 } }
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let(:primary_person) { FactoryGirl.create(:person) }
        let(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }

        it "logs failed to find primary family for users person in xml error" do
          allow(Person).to receive(:where).and_return([primary_person])
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find primary family for users person in xml/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with primary person, family, body, a valid application, return status and not connected to application to person" do
        let(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id, "return_status" => 203 } }
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let(:primary_person) { FactoryGirl.create(:person) }
        let!(:primary_person_family)  { FactoryGirl.create(:family, :with_primary_family_member, person: primary_person) }
        let(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, family: family, aasm_state: "submitted")
        }

        it "logs failed to find application for person in xml error" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find the Application in XML/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with primary person, family, body, a valid application, return status and not connected to application to tax household" do
        let(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 203 } }
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }
        let(:tax_household) { FactoryGirl.create(:tax_household, application: application) }

        it "logs failed to find Tax Households in our DB with the ids in xml error" do
          allow(Person).to receive(:where).and_return([person])
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find Tax Households in our DB with the ids in xml/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with primary person, family, body, a valid application, return status and Failed to update tax household" do
        let!(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 203 } }
        let!(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let!(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }

        it "logs Failure to update tax household" do
          allow(Person).to receive(:where).and_return([person])
          allow(HbxProfile).to receive(:current_hbx).and_return(nil)
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/Failure to update tax household/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end
    end

    context "with a valid application primary person and family" do
      let(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 203 } }
      let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }

      let(:person) { FactoryGirl.create(:person) }
      let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
      let!(:application) {
        FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
      }
      let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id) }

      before do
        allow(Person).to receive(:where).and_return([person])
        family.latest_household.tax_households << TaxHousehold.new(effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record - 1.years)
        tax_household = family.latest_household.tax_households.first
        tax_household.update_attribute("hbx_assigned_id", "#{parser.households.first.tax_households.first.hbx_assigned_id}")
      end

      it "should not log any errors" do
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
      end
    end
  end

  describe "given a valid payload with a medicad member and get status 200" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "haven_eligibility_response_payloads", "verified_3_aptc_members_1_thh_200_status.xml")) }

    context "update application as determined with status code" do
      let(:message) { { "body" => xml } }

      after do
        FinancialAssistance::Application.delete_all
        Family.delete_all
        TaxHousehold.delete_all
      end

      it "logs the failed to find the application error" do
        expect(subject).to receive(:log) do |arg1, arg2|
          expect(arg1).to eq message["body"]
          expect(arg2[:error_message]).to match(/ERROR: Failed to find the Application in XML/)
          expect(arg2[:severity]).to eq("critical")
        end
        subject.call(nil, nil, nil, nil, message)
      end

      context "with a valid application and return status" do
        let(:message) { { "body" => "", "assistance_application_id" => application.hbx_id, "return_status" => 200 } }
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }

        it "logs the failed to validate the XML against FAA XSD error" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to validate Eligibility Determination response XML/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "without person, with body, a valid application and return status" do
        let(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 200 } }
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }

        it "logs the failed to find primary person in xml error" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find primary person in xml/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "without primary person family, with primary person, body, a valid application and return status" do
        let(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 200 } }
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let(:primary_person) { FactoryGirl.create(:person) }
        let(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }

        it "logs failed to find primary family for users person in xml error" do
          allow(Person).to receive(:where).and_return([primary_person])
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find primary family for users person in xml/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with primary person, family, body, a valid application, return status and not connected to application to person" do
        let(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id, "return_status" => 200 } }
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let(:primary_person) { FactoryGirl.create(:person) }
        let!(:primary_person_family)  { FactoryGirl.create(:family, :with_primary_family_member, person: primary_person) }
        let(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, family: family, aasm_state: "submitted")
        }

        it "logs failed to find application for person in xml error" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find the Application in XML/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with primary person, family, body, a valid application, return status and not connected to application to tax household" do
        let!(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 200 } }
        let!(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let!(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }

        it "logs failed to find Tax Households in our DB with the ids in xml error" do
          allow(Person).to receive(:where).and_return([person])
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find Tax Households in our DB with the ids in xml/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with primary person, family, body, a valid application, return status, connected to application and Failed to find dependent" do
        let(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 200 } }
        let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let(:primary_person) { FactoryGirl.create(:person) }
        let!(:primary_person_family)  { FactoryGirl.create(:family, :with_primary_family_member, person: primary_person) }
        let(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:household) { family.households.first }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }

        it "logs failed to find application for person in xml error" do
          verified_primary_family_member = parser.family_members.detect{ |fm| fm.person.hbx_id == parser.primary_family_member_id }
          ssn = verified_primary_family_member.person_demographics.ssn
          dob = verified_primary_family_member.person_demographics.birth_date
          allow(Person).to receive(:where).and_call_original
          allow(Person).to receive(:where).with({:encrypted_ssn => Person.encrypt_ssn(ssn), :dob => dob}).and_return([person])
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/Failed to find dependent from xml/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with primary person, family, body, a valid application, return status and Failed to update tax household" do
        let!(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 200 } }
        let!(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }
        let!(:person) { FactoryGirl.create(:person) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
        }

        it "logs Failure to update tax household" do
          allow(Person).to receive(:where).and_return([person])
          allow(HbxProfile).to receive(:current_hbx).and_return(nil)
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/Failure to update tax household/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end
    end

    context "with a valid application primary person and family" do
      let(:message) { { "body" => xml, "assistance_application_id" => application.hbx_id, "return_status" => 200 } }
      let(:parser) { Parsers::Xml::Cv::HavenVerifiedFamilyParser.new.parse(xml) }

      let(:person) { FactoryGirl.create(:person) }
      let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
      let!(:application) {
        FactoryGirl.create(:application, hbx_id: "#{parser.fin_app_id}", family: family, aasm_state: "submitted")
      }
      let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id) }

      before do
        allow(Person).to receive(:where).and_return([person])
        family.latest_household.tax_households << TaxHousehold.new(effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record - 1.years)
        tax_household = family.latest_household.tax_households.first
        tax_household.update_attribute("hbx_assigned_id", "#{parser.households.first.tax_households.first.hbx_assigned_id}")
      end

      it "should not log any errors" do
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
      end
    end
  end

  describe '.search_person' do
    let(:subject) {Subscribers::FinancialAssistanceApplicationEligibilityResponse.new}
    let(:verified_family_member) {
      double(
        person: double(name_last: db_person.last_name, name_first: db_person.first_name),
        person_demographics: double(birth_date: db_person.dob, ssn: db_person.ssn)
      )
    }
    let(:ssn_demographics) { double(birth_date: db_person.dob, ssn: '123123123') }

    after(:each) do
      DatabaseCleaner.clean
    end

    context "with a person with a first name, last name, dob and no SSN" do
      let(:db_person) { Person.create!(first_name: "Joe", last_name: "Kramer", dob: "1993/03/30") }
      let(:person_case) { double(name_last: db_person.last_name.upcase, name_first: db_person.first_name.downcase, dob: "1993/03/30") }

      it 'finds the person by last_name, first name and dob if both payload and person have no ssn' do
        expect(subject.search_person(verified_family_member)).to eq db_person
      end

      it 'finds the person by ignoring case in payload' do
        allow(verified_family_member).to receive(:person).and_return(person_case)
        expect(subject.search_person(verified_family_member)).to eq db_person
      end

      it 'does not find the person if payload has ssn and person has ssn' do
        allow(verified_family_member).to receive(:person_demographics).and_return(ssn_demographics)
        expect(subject.search_person(verified_family_member)).to eq nil
      end
    end

    context "with a person with a first name, last name, dob and ssn" do
      let(:db_person) { Person.create!(first_name: "Jack",   last_name: "Weiner",   dob: "1943/05/14", ssn: "517994321")}

      it 'finds the person by ssn name and dob if both payload and person have a ssn' do
        expect(subject.search_person(verified_family_member)).to eq db_person
      end

      it 'does not find the person if payload has a different ssn from the person' do
        allow(verified_family_member).to receive(:person_demographics).and_return(ssn_demographics)
        expect(subject.search_person(verified_family_member)).to eq nil
      end
    end
  end
end
