require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe Subscribers::FamilyApplicationCompleted do
  let(:hbx_profile_organization) { double("HbxProfile", benefit_sponsorship:  double(current_benefit_coverage_period: double(slcsp: Plan.new.id)))}
  let(:max_aptc) { parser.households.select do |h|
    h.integrated_case_id == parser.integrated_case_id
  end.first.tax_households.select do |th|
    th.primary_applicant_id == parser.family_members.detect do |fm|
      fm.id == parser.primary_family_member_id
    end.id.split('#').last
  end.select do |th|
    th.id == th.primary_applicant_id && th.primary_applicant_id == parser.primary_family_member_id.split('#').last
  end.first.eligibility_determinations.max_by(&:determination_date).maximum_aptc }

  it "should subscribe to the correct event" do
    expect(Subscribers::FamilyApplicationCompleted.subscription_details).to eq ["acapi.info.events.family.application_completed"]
  end

  before do
    allow(HbxProfile).to receive(:current_hbx).and_return(hbx_profile_organization)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "errors logged given a payload" do
    let(:message) { { "body" => xml } }

    context "with valid single member" do
      let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_sample.xml")) }

      context "with no person matched to user and no primary family associated with the person" do
        it "log both No person and Failed to find primary family errors" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/ERROR: Failed to find primary person in xml/)
            expect(arg2[:severity]).to eq "critical"
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with no person matched to user and no primary family associated with the person" do
        let(:person) { FactoryGirl.create(:person) }

        before do
          allow(Person).to receive(:where).and_return([person])
        end

        it "logs the failed to find primary family error" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq message["body"]
            expect(arg2[:error_message]).to match(/Failed to find primary family for users person/)
            expect(arg2[:severity]).to eq("critical")
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with a valid single person family" do

        let(:message) { { "body" => xml } }
        let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_no_ssn_sample.xml")) }
        let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_no_ssn_sample.xml"))).first }
        let(:user) { FactoryGirl.create(:user) }

        let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
        let(:ua_params) do
          {
            addresses: [],
            phones: [],
            emails: [],
            person: {
              "first_name" => primary.person.name_first.upcase,
              "last_name" => primary.person.name_last.downcase,
              "middle_name" => primary.person.name_middle,
              "name_pfx" => primary.person.name_pfx,
              "name_sfx" => primary.person.name_sfx,
              "dob" => primary.person_demographics.birth_date,
              "ssn" => primary.person_demographics.ssn,
              "no_ssn" => "1",
              "gender" => primary.person_demographics.sex.split('#').last
            }
          }
        end

        let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }
        let(:family) { consumer_role.person.primary_family }

        before do
          family.update_attribute(:e_case_id, "curam_landing_for#{consumer_role.person.id}")
          allow(HbxProfile).to receive(:current_hbx).and_return(hbx_profile_organization)
        end

        after do
          Family.delete_all
        end

        it "shouldn't log any errors the first time" do
          expect(subject).not_to receive(:log)
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with another valid single person family" do

        let(:message) { { "body" => xml } }
        let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_sample.xml")) }
        let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_sample.xml"))).first }
        let(:user) { FactoryGirl.create(:user) }

        let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
        let(:ua_params) do
          {
            addresses: [],
            phones: [],
            emails: [],
            person: {
              "first_name" => primary.person.name_first.upcase,
              "last_name" => primary.person.name_last.downcase,
              "middle_name" => primary.person.name_middle,
              "name_pfx" => primary.person.name_pfx,
              "name_sfx" => primary.person.name_sfx,
              "dob" => primary.person_demographics.birth_date,
              "ssn" => primary.person_demographics.ssn,
              "no_ssn" => "1",
              "gender" => primary.person_demographics.sex.split('#').last
            }
          }
        end

        let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }
        let(:family) { consumer_role.person.primary_family }

        before do
          allow(HbxProfile).to receive(:current_hbx).and_return(hbx_profile_organization)
        end

        after do
          Family.delete_all
        end

        it "shouldn't log any errors the first time" do
          family.update_attribute(:e_case_id, nil)
          expect(subject).not_to receive(:log)
          subject.call(nil, nil, nil, nil, message)
        end
      end
    end
  end

  describe "given a valid payload with a user with a broker" do
    let(:message) { { "body" => xml } }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_with_broker_sample.xml")) }
    let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_with_broker_sample.xml"))).first }
    let(:user) { FactoryGirl.create(:user) }

    context "simulating consumer role controller create action with first and last name cases that do not match the payload" do
      let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
      let(:person) { consumer_role.person }
      let(:ua_params) do
        {
          addresses: [],
          phones: [],
          emails: [],
          person: {
            "first_name" => primary.person.name_first.upcase,
            "last_name" => primary.person.name_last.downcase,
            "middle_name" => primary.person.name_middle,
            "name_pfx" => primary.person.name_pfx,
            "name_sfx" => primary.person.name_sfx,
            "dob" => primary.person_demographics.birth_date,
            "ssn" => primary.person_demographics.ssn,
            "no_ssn" => "1",
            "gender" => primary.person_demographics.sex.split('#').last
          }
        }
      end

      let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }

      let(:family_db) { Family.where(e_case_id: parser.integrated_case_id).first }
      let(:tax_household_db) { family_db.active_household.tax_households.first }
      let(:person_db) { family_db.primary_applicant.person }
      let(:consumer_role_db) { person_db.consumer_role }

      context "with npn that does not exist with a broker" do
        it "should not log any errors" do
          person.primary_family.update_attribute(:e_case_id, "curam_landing_for#{person.id}")
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to eq(message["body"])
            expect(arg2[:error_message]).to match(/Failed to match broker with npn/)
            expect(arg2[:severity]).to eq('critical')
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with valid broker's npn" do
        let!(:broker_agency_profile) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_broker_agency_profile).broker_agency_profile}
        let!(:update) {broker_agency_profile.update_attributes(primary_broker_role_id:broker.id)}
        let(:broker) {FactoryGirl.create(:broker_role,benefit_sponsors_broker_agency_profile_id:broker_agency_profile.id)}
        let(:broker_id) { broker_agency_profile.primary_broker_role.id }

        it "should not log any errors and set the broker for the family" do
          broker_agency_profile.primary_broker_role.update_attributes(npn: "1234567890", benefit_sponsors_broker_agency_profile_id:broker_agency_profile.id,broker_agency_profile_id: broker_agency_profile.id)
          person.primary_family.update_attribute(:e_case_id, "curam_landing_for#{person.id}")
          expect(subject).not_to receive(:log)
          subject.call(nil, nil, nil, nil, message)
          expect(family_db.current_broker_agency.benefit_sponsors_broker_agency_profile_id).to eq broker_agency_profile.id
          expect(family_db.current_broker_agency.writing_agent_id).to eq broker_id
        end

        it "should update the users identity final decision code" do
          expect(consumer_role_db.person.user.identity_final_decision_code).to eq User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
          expect(consumer_role_db.person.user.identity_response_code).to eq User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
          expect(consumer_role_db.person.user.identity_response_description_text).to eq "curam payload"
          expect(consumer_role_db.person.user.identity_verified_date).to eq TimeKeeper.date_of_record
        end

        it "updates the tax household with aptc from the payload on the primary persons family" do
          expect(tax_household_db).to be_truthy
          expect(tax_household_db).to eq person.primary_family.active_household.latest_active_tax_household
          expect(tax_household_db.primary_applicant.family_member.person).to eq person
          expect(tax_household_db.allocated_aptc).to eq 0
          expect(tax_household_db.is_eligibility_determined).to be_truthy
          expect(tax_household_db.current_max_aptc).to eq max_aptc
        end

        it "updates all consumer role verifications" do
          expect(consumer_role_db.fully_verified?).to be_truthy
          expect(consumer_role_db.vlp_authority).to eq "curam"
          expect(consumer_role_db.residency_determined_at).to eq primary.created_at
          expect(consumer_role_db.citizen_status).to eq primary.verifications.citizen_status.split('#').last
          expect(consumer_role_db.is_state_resident).to eq primary.verifications.is_lawfully_present
          expect(consumer_role_db.is_incarcerated).to eq primary.person_demographics.is_incarcerated
        end

        it "updates the address for the primary applicant's person" do
          expect(person_db.addresses).to be_truthy
        end
      end
    end
  end

  describe "given a valid payload with a user with no ssn" do
    let(:message) { { "body" => xml } }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_no_ssn_sample.xml")) }
    let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_no_ssn_sample.xml"))).first }
    let(:user) { FactoryGirl.create(:user) }

    context "simulating consumer role controller create action with first and last name cases that do not match the payload" do
      let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
      let(:person) { consumer_role.person }
      let(:ua_params) do
        {
          addresses: [],
          phones: [],
          emails: [],
          person: {
            "first_name" => primary.person.name_first.upcase,
            "last_name" => primary.person.name_last.downcase,
            "middle_name" => primary.person.name_middle,
            "name_pfx" => primary.person.name_pfx,
            "name_sfx" => primary.person.name_sfx,
            "dob" => primary.person_demographics.birth_date,
            "ssn" => primary.person_demographics.ssn,
            "no_ssn" => "1",
            "gender" => primary.person_demographics.sex.split('#').last
          }
        }
      end

      let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }

      let(:family_db) { Family.where(e_case_id: parser.integrated_case_id).first }
      let(:tax_household_db) { family_db.active_household.tax_households.first }
      let(:person_db) { family_db.primary_applicant.person }
      let(:consumer_role_db) { person_db.consumer_role }

      it "should not log any errors" do
        person.primary_family.update_attribute(:e_case_id, "curam_landing_for#{person.id}")
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
      end

      it "should update the users identity final decision code" do
        expect(consumer_role_db.person.user.identity_final_decision_code).to eq User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
        expect(consumer_role_db.person.user.identity_response_code).to eq User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
        expect(consumer_role_db.person.user.identity_response_description_text).to eq "curam payload"
        expect(consumer_role_db.person.user.identity_verified_date).to eq TimeKeeper.date_of_record
      end

      it "updates the tax household with aptc from the payload on the primary persons family" do
        expect(tax_household_db).to be_truthy
        expect(tax_household_db).to eq person.primary_family.active_household.latest_active_tax_household
        expect(tax_household_db.primary_applicant.family_member.person).to eq person
        expect(tax_household_db.allocated_aptc).to eq 0
        expect(tax_household_db.is_eligibility_determined).to be_truthy
        expect(tax_household_db.current_max_aptc).to eq max_aptc
      end

      it "updates all consumer role verifications" do
        expect(consumer_role_db.fully_verified?).to be_truthy
        expect(consumer_role_db.vlp_authority).to eq "curam"
        expect(consumer_role_db.residency_determined_at).to eq primary.created_at
        expect(consumer_role_db.citizen_status).to eq primary.verifications.citizen_status.split('#').last
        expect(consumer_role_db.is_state_resident).to eq primary.verifications.is_lawfully_present
        expect(consumer_role_db.is_incarcerated).to eq primary.person_demographics.is_incarcerated
      end

      it "updates the address for the primary applicant's person" do
        expect(person_db.addresses).to be_truthy
      end
    end
  end

  describe "given a valid payload more than once" do
    let(:message) { { "body" => xml } }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_single_dup_payload_sample.xml")) }
    let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_single_dup_payload_sample.xml"))).first }
    let(:user) { FactoryGirl.create(:user) }

    context "simulating consumer role controller create action" do
      let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
      let(:person) { consumer_role.person }
      let(:ua_params) do
        {
          addresses: [],
          phones: [],
          emails: [],
          person: {
            "first_name" => primary.person.name_first,
            "last_name" => primary.person.name_last,
            "middle_name" => primary.person.name_middle,
            "name_pfx" => primary.person.name_pfx,
            "name_sfx" => primary.person.name_sfx,
            "dob" => primary.person_demographics.birth_date,
            "ssn" => primary.person_demographics.ssn,
            "no_ssn" => "",
            "gender" => primary.person_demographics.sex.split('#').last
          }
        }
      end

      let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }

      let(:family_db) { Family.where(e_case_id: parser.integrated_case_id).first }
      let(:tax_household_db) { family_db.active_household.tax_households.first }
      let(:person_db) { family_db.primary_applicant.person }
      let(:consumer_role_db) { person_db.consumer_role }

      it "should not log any errors initially" do
        person.primary_family.update_attribute(:e_case_id, "curam_landing_for#{person.id}")
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
      end

      it "updates the tax household with aptc from the payload on the primary persons family" do
        expect(tax_household_db).to be_truthy
        expect(tax_household_db).to eq person.primary_family.active_household.latest_active_tax_household
        expect(tax_household_db.primary_applicant.family_member.person).to eq person
        expect(tax_household_db.allocated_aptc).to eq 0
        expect(tax_household_db.is_eligibility_determined).to be_truthy
        expect(tax_household_db.current_max_aptc).to eq max_aptc
      end

      it "updates all consumer role verifications" do
        expect(consumer_role_db.fully_verified?).to be_truthy
        expect(consumer_role_db.vlp_authority).to eq "curam"
        expect(consumer_role_db.residency_determined_at).to eq primary.created_at
        expect(consumer_role_db.citizen_status).to eq primary.verifications.citizen_status.split('#').last
        expect(consumer_role_db.is_state_resident).to eq primary.verifications.is_lawfully_present
        expect(consumer_role_db.is_incarcerated).to eq primary.person_demographics.is_incarcerated
      end

      it "updates the address for the primary applicant's person" do
        expect(person_db.addresses).to be_truthy
      end

      it "can recieve duplicate payloads without logging errors" do
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
      end

      it "does should contain both tax households with one of them having an end on date" do
        expect(family_db.active_household.tax_households.length).to eq 2
        expect(family_db.active_household.tax_households.select{|th| th.effective_ending_on.present? }).to be_truthy
      end

      it "maintain the old tax household" do
        expect(tax_household_db).to be_truthy
        expect(tax_household_db.primary_applicant.family_member.person).to eq person
        expect(tax_household_db.allocated_aptc).to eq 0
        expect(tax_household_db.is_eligibility_determined).to be_truthy
        expect(tax_household_db.current_max_aptc).to eq max_aptc
        expect(tax_household_db.effective_ending_on).to be_truthy
      end

      it "should have a new tax household with the same aptc data" do
        updated_tax_household = tax_household_db.household.latest_active_tax_household
        expect(updated_tax_household).to be_truthy
        expect(updated_tax_household.primary_applicant.family_member.person).to eq person
        expect(updated_tax_household.allocated_aptc).to eq 0
        expect(updated_tax_household.is_eligibility_determined).to be_truthy
        expect(updated_tax_household.current_max_aptc).to eq max_aptc
        expect(updated_tax_household.effective_ending_on).not_to be_truthy
      end
    end
  end

  describe "given a valid payload with more multiple members and multiple coverage households" do
    let(:message) { { "body" => xml } }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_4_member_family_sample.xml")) }
    let(:user) { FactoryGirl.create(:user) }

    context "simulating consumer role controller create action" do
      let!(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_4_member_family_sample.xml"))).first }
      let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
      let(:dependent) { parser.family_members.last }
      let!(:existing_dep ) { Person.create(
          first_name: dependent.person.name_first,
          last_name: dependent.person.name_last,
          middle_name: dependent.person.name_middle,
          name_pfx: dependent.person.name_pfx,
          name_sfx: dependent.person.name_sfx,
          dob: dependent.person_demographics.birth_date,
          ssn: dependent.person_demographics.ssn == "999999999" ? "" : dependent.person_demographics.ssn ,
          gender: dependent.person_demographics.sex.split('#').last
        )}
      let(:person) { consumer_role.person }
      let(:ua_params) do
        {
          addresses: [],
          phones: [],
          emails: [],
          person: {
            "first_name" => primary.person.name_first,
            "last_name" => primary.person.name_last,
            "middle_name" => primary.person.name_middle,
            "name_pfx" => primary.person.name_pfx,
            "name_sfx" => primary.person.name_sfx,
            "dob" => primary.person_demographics.birth_date,
            "ssn" => primary.person_demographics.ssn,
            "no_ssn" => "",
            "gender" => primary.person_demographics.sex.split('#').last
          }
        }
      end

      let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }

      let(:family_db) { Family.where(e_case_id: parser.integrated_case_id).first }
      let(:tax_household_db) { family_db.active_household.tax_households.first }
      let(:person_db) { family_db.primary_applicant.person }
      let(:consumer_role_db) { person_db.consumer_role }
      let(:new_dep_consumer_role_db) { family_db.dependents.first.person.consumer_role }
      let(:existing_dep_consumer_role_db) { Person.where(first_name: "Megan", last_name: "Zoo").first.consumer_role }

      it "should not log any errors" do
        person.primary_family.update_attribute(:e_case_id, "curam_landing_for#{person.id}")
        expect(subject).not_to receive(:log)
        subject.call(nil, nil, nil, nil, message)
      end

      it "updates the tax household with aptc from the payload on the primary persons family" do
        expect(tax_household_db).to be_truthy
        expect(tax_household_db).to eq person.primary_family.active_household.latest_active_tax_household
        expect(tax_household_db.primary_applicant.family_member.person).to eq person
        expect(tax_household_db.allocated_aptc).to eq 0
        expect(tax_household_db.is_eligibility_determined).to be_truthy
        expect(tax_household_db.current_max_aptc).to eq max_aptc
      end

      it "has 4 tax household members with primary person as primary tax household member" do
        expect(tax_household_db.tax_household_members.length).to eq 4
        expect(tax_household_db.tax_household_members.map(&:is_primary_applicant?)).to eq [true,false,false,false]
        expect(tax_household_db.tax_household_members.select{|thm| thm.is_primary_applicant?}.first.family_member).to eq person.primary_family.primary_family_member
      end

      it "has 2 coverage households with 4 members in immediate family" do
        expect(tax_household_db.household.coverage_households.length).to eq 2
        expect(tax_household_db.household.coverage_households.where(is_immediate_family: true).first.coverage_household_members.length).to eq 4
        expect(tax_household_db.household.coverage_households.first.coverage_household_members.select{|thm| thm.is_subscriber?}.first.family_member).to eq person.primary_family.primary_family_member
      end

      it "has 2 coverage households with 0 members in non-immediate family" do
        expect(tax_household_db.household.coverage_households.where(is_immediate_family: false).first.coverage_household_members.length).to eq 0
      end

      it "should has the following relations under primary family person" do
        expect(family_db.family_members.map(&:primary_relationship)).to eq ["self", "spouse", "child", "child"]
      end

      it "updates all consumer role verifications" do
        expect(consumer_role_db.fully_verified?).to be_truthy
        expect(consumer_role_db.vlp_authority).to eq "curam"
        expect(consumer_role_db.residency_determined_at).to eq primary.created_at
        expect(consumer_role_db.citizen_status).to eq primary.verifications.citizen_status.split('#').last
        expect(consumer_role_db.is_state_resident).to eq primary.verifications.is_lawfully_present
        expect(consumer_role_db.is_incarcerated).to eq primary.person_demographics.is_incarcerated
      end

      it "updates the address for the primary applicant's person" do
        expect(person_db.addresses).to be_truthy
      end

      context "recieving a new payload with one family member removed" do
        let(:minus_message) { { "body" => minus_xml } }
        let(:minus_xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_4_member_family_minus_one_sample.xml")) }

        it "should not log any errors" do
          expect(subject).not_to receive(:log)
          subject.call(nil, nil, nil, nil, minus_message)
        end

        it "should build a new household with 3 coverage household members and 3 taxhousehold members" do
          # updated_tax_household = tax_household_db.household.latest_active_tax_household
          # expect(tax_household_db.tax_household_members.length).to eq 3
          # expect(tax_household_db.tax_household_members.map(&:is_primary_applicant?)).to eq [true,false,false]
          # expect(tax_household_db.tax_household_members.select{|thm| thm.is_primary_applicant?}.first.family_member).to eq person.primary_family.primary_family_member
          # expect(tax_household_db.household.coverage_households.length).to eq 2
          # expect(tax_household_db.household.coverage_households.first.coverage_household_members.length).to eq 1
          # expect(tax_household_db.household.coverage_households.first.coverage_household_members.select{|thm| thm.is_subscriber?}.first.family_member).to eq person.primary_family.primary_family_member
        end



        it "should maintain the old household as inactive and give the tax household an end on date" do
          #   expect(family_db.active_household.tax_households.length).to eq 2
          #   expect(family_db.active_household.tax_households.select{|th| th.effective_ending_on.present? }).to be_truthy
          #   expect(tax_household_db).to be_truthy
          #   expect(tax_household_db.primary_applicant.family_member.person).to eq person
          #   expect(tax_household_db.allocated_aptc).to eq 0
          #   expect(tax_household_db.is_eligibility_determined).to be_truthy
          #   expect(tax_household_db.current_max_aptc).to eq 71
          #   expect(tax_household_db.effective_ending_on).to be_truthy
        end

        it "updates all consumer role verifications" do
          expect(consumer_role_db.fully_verified?).to be_truthy
          expect(consumer_role_db.vlp_authority).to eq "curam"
          expect(consumer_role_db.residency_determined_at).to eq primary.created_at
          expect(consumer_role_db.citizen_status).to eq primary.verifications.citizen_status.split('#').last
          expect(consumer_role_db.is_state_resident).to eq primary.verifications.is_lawfully_present
          expect(consumer_role_db.is_incarcerated).to eq primary.person_demographics.is_incarcerated
        end

        it "updates all consumer role verifications for dependents new to the system" do
          expect(new_dep_consumer_role_db.fully_verified?).to be_truthy
          expect(new_dep_consumer_role_db.vlp_authority).to eq "curam"
          expect(new_dep_consumer_role_db.residency_determined_at).to eq primary.created_at
          expect(new_dep_consumer_role_db.citizen_status).to eq primary.verifications.citizen_status.split('#').last
          expect(new_dep_consumer_role_db.is_state_resident).to eq primary.verifications.is_lawfully_present
          expect(new_dep_consumer_role_db.is_incarcerated).to eq primary.person_demographics.is_incarcerated
        end

        it "updates all consumer role verifications for dependents who already exist in the system" do
          expect(existing_dep_consumer_role_db.fully_verified?).to be_truthy
          expect(existing_dep_consumer_role_db.vlp_authority).to eq "curam"
          expect(existing_dep_consumer_role_db.residency_determined_at).to eq primary.created_at
          expect(existing_dep_consumer_role_db.citizen_status).to eq primary.verifications.citizen_status.split('#').last
          expect(existing_dep_consumer_role_db.is_state_resident).to eq primary.verifications.is_lawfully_present
          expect(existing_dep_consumer_role_db.is_incarcerated).to eq primary.person_demographics.is_incarcerated
        end

        it "updates the address for the primary applicant's person" do
          expect(person_db.addresses).to be_truthy
        end
      end
    end
  end
end

describe '.search_person' do
  let(:subject) {Subscribers::FamilyApplicationCompleted.new}
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
    let(:db_person) { Person.create!(first_name: "Joe", last_name: "Kramer", dob: "1993-03-30") }
    let(:person_case) { double(name_last: db_person.last_name.upcase, name_first: db_person.first_name.downcase) }

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
    let(:db_person) { Person.create!(first_name: "Jack",   last_name: "Weiner",   dob: "1943-05-14", ssn: "517994321")}

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
