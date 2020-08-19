require "rails_helper"

describe Subscribers::FinancialAssistanceApplicationOutstandingVerification, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

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

        context "for a valid import" do
          let(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id} }
          let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id, aasm_state: 'verification_pending')}
          let!(:mec_assisted_verification) { FactoryGirl.create(:verification_type, applicant: applicant, type_name: 'MEC', validation_status: "pending") }

          it "should not log any errors and updates the existing verification_types" do
            allow(Person).to receive(:where).and_return([person])
            expect(subject).not_to receive(:log)
            subject.call(nil, nil, nil, nil, message)
            mec_assisted_verification.reload
            expect(mec_assisted_verification.validation_status).to eq "outstanding"
            expect(applicant.verification_types.mec.count).to eq 1
          end

          it "should not log any errors and creates new verification_types for applicant" do
            mec_assisted_verification.update_attributes(validation_status: "unverified")
            allow(Person).to receive(:where).and_return([person])
            expect(subject).not_to receive(:log)
            subject.call(nil, nil, nil, nil, message)
            expect(mec_assisted_verification.validation_status).to eq "unverified"
            applicant.reload
            expect(applicant.verification_types.mec.count).to eq 1
          end
        end
      end
    end
  end

  describe "Did not receive response within 24 hours", dbclean: :after_each do
    let!(:xml) { File.read(Rails.root.join("spec", "test_data", "haven_outstanding_verification_response", "external_verifications_mec_sample.xml")) }
    let!(:parser) { Parsers::Xml::Cv::OutstandingMecVerificationParser.new.parse(xml) }
    let!(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let!(:application) do
      FactoryGirl.create(:application, id: parser.fin_app_id.to_s, family: family, aasm_state: "determined")
    end
    let(:message) { { "return_status" => 503, "body" => xml, "assistance_application_id" => parser.fin_app_id} }
    let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id, aasm_state: 'verification_pending')}
    let!(:mec_assisted_verification) { FactoryGirl.create(:verification_type, applicant: applicant, type_name: 'MEC', validation_status: "pending") }
    let!(:income_assisted_verification) { FactoryGirl.create(:verification_type, applicant: applicant, type_name: 'Income', validation_status: "pending") }


    context 'no response for MEC within 24 hours' do

      before do
        applicant.update_attributes(has_income_verification_response: true)
        income_assisted_verification.update_attributes(validation_status: 'verified')
      end

      it 'should move applicant to outstanding status' do
        allow(Person).to receive(:where).and_return([person])
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
        applicant.reload
        mec_assisted_verification.reload
        expect(mec_assisted_verification.validation_status).to eq "outstanding"
        expect(applicant.aasm_state).to eq "verification_outstanding"
      end
    end

    context 'no response for Income within 24 hours' do

      before do
        applicant.update_attributes(has_mec_verification_response: true)
        mec_assisted_verification.update_attributes(validation_status: 'verified')
      end

      it 'should move applicant to outstanding status' do
        allow(Person).to receive(:where).and_return([person])
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
        applicant.reload
        income_assisted_verification.reload
        expect(income_assisted_verification.validation_status).to eq "outstanding"
        expect(applicant.aasm_state).to eq "verification_outstanding"
      end
    end

    context 'no response for both Income and MEC within 24 hours' do

      it 'should move applicant to outstanding status' do
        allow(Person).to receive(:where).and_return([person])
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
        applicant.reload
        income_assisted_verification.reload
        mec_assisted_verification.reload
        expect(income_assisted_verification.validation_status).to eq "outstanding"
        expect(mec_assisted_verification.validation_status).to eq "outstanding"
        expect(applicant.aasm_state).to eq "verification_outstanding"
      end
    end
  end

  describe "given a valid payload for Income Verification" do
    let!(:xml) { File.read(Rails.root.join("spec", "test_data", "haven_outstanding_verification_response", "external_verifications_income_sample.xml")) }

    context "for updating respective instances on import" do

      context "for import Income Verification" do
        let!(:parser) { Parsers::Xml::Cv::OutstandingMecVerificationParser.new.parse(xml) }
        let!(:person) { FactoryGirl.create(:person, :with_consumer_role) }
        let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
        let!(:application) {
          FactoryGirl.create(:application, id: "#{parser.fin_app_id}", family: family, aasm_state: "determined")
        }
        let!(:message) { { "body" => xml, "assistance_application_id" => parser.fin_app_id} }
        let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id, aasm_state: 'verification_pending')}
        let!(:income_assisted_verification) do
          applicant.verification_types << FactoryGirl.create(:verification_type, applicant: applicant, type_name: 'Income', validation_status: "pending")
          applicant.verification_types.income.first
        end

        context "for a valid import" do
          let!(:income_assisted_verification) do
            applicant.verification_types << FactoryGirl.create(:verification_type, applicant: applicant, type_name: 'Income', validation_status: "pending")
            applicant.verification_types.income.first
          end

          it "should not log any errors and updates the existing verification_types" do
            allow(Person).to receive(:where).and_return([person])
            expect(subject).not_to receive(:log)
            subject.call(nil, nil, nil, nil, message)
            applicant.reload
            income_assisted_verification.reload
            expect(income_assisted_verification.validation_status).to eq "pending"
            expect(applicant.verification_types.income.count).to eq 2
            expect(applicant.assisted_income_validation).to eq "outstanding"
            expect(applicant.aasm_state).to eq "verification_outstanding"
          end

          it "should not log any errors and creates new verification_types for applicant" do
            income_assisted_verification.update_attributes(validation_status: "unverified")
            allow(Person).to receive(:where).and_return([person])
            expect(subject).not_to receive(:log)
            subject.call(nil, nil, nil, nil, message)
            expect(income_assisted_verification.validation_status).to eq "unverified"
            applicant.reload
            expect(applicant.verification_types.income.count).to eq 2
            expect(applicant.assisted_income_validation).to eq "outstanding"
            expect(applicant.aasm_state).to eq "verification_outstanding"
          end
        end
      end
    end
  end

  describe 'store_payload', dbclean: :after_each do
    let!(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let!(:application) { FactoryGirl.create(:application, family: family, aasm_state: "determined") }
    let!(:applicant) { FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id, aasm_state: 'verification_pending')}

    before do
      subject.instance_variable_set(:@applicant_in_context, applicant)
    end

    ['Income', 'MEC'].each do |kind|
      context kind.to_s do
        before do
          subject.send(:store_payload, kind, "sample payload xml")
        end

        it 'should return the object' do
          expect(applicant.send(kind.downcase + '_response')).to be_an_instance_of(EventResponse)
        end
      end
    end
  end
end