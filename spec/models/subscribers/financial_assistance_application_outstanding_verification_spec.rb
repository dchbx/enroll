require "rails_helper"

describe Subscribers::FinancialAssistanceApplicationOutstandingVerification do

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    allow_any_instance_of(Family).to receive(:application_applicable_year).and_return(TimeKeeper.date_of_record.year)
  end

  it "should subscribe to the correct event" do
    expect(Subscribers::FinancialAssistanceApplicationOutstandingVerification.subscription_details).to eq ["acapi.info.events.outstanding_verification.submitted"]
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  after do
    FinancialAssistance::Application.delete_all
    Family.delete_all
  end

  describe "given a valid payload for MEC Verification" do
    let!(:xml) { File.read(Rails.root.join("spec", "test_data", "haven_outstanding_verification_response", "external_verifications_mec_sample.xml")) }

    context "for updating respective instances on import" do
      let(:message) { { "body" => xml } }

      it "logs failed to find the application error" do
        expect(subject).to receive(:log) do |arg1, arg2|
          expect(arg1).to eq message["body"]
          expect(arg2[:error_message]).to match(/ERROR: Failed to find the Application or Determined Application in XML/)
          expect(arg2[:severity]).to eq("critical")
        end
        subject.call(nil, nil, nil, nil, message)
      end

      context "for import MEC Verification" do
        let!(:parser) { Parsers::Xml::Cv::OutstandingMecVerificationParser.new.parse(xml) }
        let!(:person) { FactoryGirl.create(:person, :with_consumer_role) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, id: "#{parser.fin_app_id}", family: family, aasm_state: "determined")
        }

        context "with an application and invalid payload" do
          let(:message) { { "body" => "", "assistance_application_id" => parser.fin_app_id} }

          it "logs the failed to validate the XML against FAA XSD error" do
            expect(subject).to receive(:log) do |arg1, arg2|
              expect(arg1).to eq message["body"]
              expect(arg2[:error_message]).to match(/ERROR: Failed to validate Verification response XML/)
              expect(arg2[:severity]).to eq("critical")
            end
            subject.call(nil, nil, nil, nil, message)
          end
        end

        context "with an application, valid payload, missing Person" do
          let(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id} }

          it "logs the failed to find primary person in xml error" do
            expect(subject).to receive(:log) do |arg1, arg2|
              expect(arg1).to eq message["body"]
              expect(arg2[:error_message]).to match("ERROR: Failed to find primary person in xml")
              expect(arg2[:severity]).to eq("critical")
            end
            subject.call(nil, nil, nil, nil, message)
          end
        end

        context "with an application, valid payload, missing Applicant" do
          let(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id} }

          it "logs the failed to find primary person in xml error" do
            allow(Person).to receive(:where).and_return([person])
            expect(subject).to receive(:log) do |arg1, arg2|
              expect(arg1).to eq message["body"]
              expect(arg2[:error_message]).to match("ERROR: Failed to find applicant in xml")
              expect(arg2[:severity]).to eq("critical")
            end
            subject.call(nil, nil, nil, nil, message)
          end
        end

        context "with an application, valid payload, missing Applicant" do
          let(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id} }
          let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id)}

          it "logs the failed to find primary person in xml error" do
            allow(Person).to receive(:where).and_return([person])
            expect(subject).to receive(:log) do |arg1, arg2|
              expect(arg1).to eq message["body"]
              expect(arg2[:error_message]).to match("ERROR: Failed to find MEC verification for the applicant")
              expect(arg2[:severity]).to eq("critical")
            end
            subject.call(nil, nil, nil, nil, message)
          end
        end

        context "for a valid import" do
          let(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id} }
          let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id)}
          let!(:mec_assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant, verification_type: "MEC", status: "pending") }

          it "should not log any errors and updates the existing assisted_verifications" do
            allow(Person).to receive(:where).and_return([person])
            expect(subject).not_to receive(:log)
            subject.call(nil, nil, nil, nil, message)
            mec_assisted_verification.reload
            expect(mec_assisted_verification.status).to eq "outstanding"
            expect(applicant.assisted_verifications.mec.count).to eq 1
          end

          it "should not log any errors and creates new assisted_verifications for applicant" do
            mec_assisted_verification.update_attributes(status: "unverified")
            allow(Person).to receive(:where).and_return([person])
            expect(subject).not_to receive(:log)
            subject.call(nil, nil, nil, nil, message)
            expect(mec_assisted_verification.status).to eq "unverified"
            applicant.reload
            expect(applicant.assisted_verifications.mec.count).to eq 2
          end
        end
      end
    end
  end

  describe "given a valid payload for Income Verification" do
    let!(:xml) { File.read(Rails.root.join("spec", "test_data", "haven_outstanding_verification_response", "external_verifications_income_sample.xml")) }

    context "for updating respective instances on import" do

      context "for import Income Verification" do
        let!(:parser) { Parsers::Xml::Cv::OutstandingMecVerificationParser.new.parse(xml) }
        let!(:person) { FactoryGirl.create(:person, :with_consumer_role) }
        let!(:consumer_role) { person.consumer_role }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, id: "#{parser.fin_app_id}", family: family, aasm_state: "determined")
        }
        let!(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id} }
        let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id)}

        context "with an application, valid payload, missing Applicant" do

          it "logs the failed to find primary person in xml error" do
            allow(Person).to receive(:where).and_return([person])
            expect(subject).to receive(:log) do |arg1, arg2|
              expect(arg1).to eq message["body"]
              expect(arg2[:error_message]).to match("ERROR: Failed to find Income verification for the applicant")
              expect(arg2[:severity]).to eq("critical")
            end
            subject.call(nil, nil, nil, nil, message)
          end
        end

        context "for a valid import" do
          let!(:income_assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant, verification_type: "Income", status: "pending") }

          it "should not log any errors and updates the existing assisted_verifications" do
            allow(Person).to receive(:where).and_return([person])
            expect(subject).not_to receive(:log)
            subject.call(nil, nil, nil, nil, message)
            consumer_role.reload
            income_assisted_verification.reload
            expect(income_assisted_verification.status).to eq "outstanding"
            expect(applicant.assisted_verifications.income.count).to eq 1
            expect(consumer_role.assisted_income_validation).to eq "outstanding"
            expect(applicant.person.consumer_role.aasm_state).to eq "verification_outstanding"
          end

          it "should not log any errors and creates new assisted_verifications for applicant" do
            income_assisted_verification.update_attributes(status: "unverified")
            allow(Person).to receive(:where).and_return([person])
            expect(subject).not_to receive(:log)
            subject.call(nil, nil, nil, nil, message)
            expect(income_assisted_verification.status).to eq "unverified"
            consumer_role.reload
            applicant.reload
            expect(applicant.assisted_verifications.income.count).to eq 2
            expect(applicant.person.consumer_role.assisted_income_validation).to eq "outstanding"
            expect(consumer_role.aasm_state).to eq "verification_outstanding"
          end
        end
      end
    end
  end
end