require "rails_helper"

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

  Dir.glob("#{Rails.root}/spec/test_data/verified_family_payloads/core_scenarios/*.xml").each do |file|
    describe "#{Pathname.new(file).basename} scenario payload" do
      let(:message) { { "body" => xml } }
      let(:xml) { File.read(file) }
      let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(file)).first }
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
          if tax_household_db
            expect(tax_household_db).to be_truthy
            expect(tax_household_db).to eq person.primary_family.active_household.latest_active_tax_households.first
            expect(tax_household_db.primary_applicant.family_member.person).to eq person
            expect(tax_household_db.allocated_aptc).to eq 0
            expect(tax_household_db.is_eligibility_determined).to be_truthy
            expect(tax_household_db.current_max_aptc).to eq max_aptc
          end
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
          if tax_household_db
            expect(family_db.active_household.tax_households.length).to eq 2
            expect(family_db.active_household.tax_households.select{|th| th.effective_ending_on.present? }).to be_truthy
          end
        end

        it "maintain the old tax household" do
          if tax_household_db
            expect(tax_household_db).to be_truthy
            expect(tax_household_db.primary_applicant.family_member.person).to eq person
            expect(tax_household_db.allocated_aptc).to eq 0
            expect(tax_household_db.is_eligibility_determined).to be_truthy
            expect(tax_household_db.current_max_aptc).to eq max_aptc
            expect(tax_household_db.effective_ending_on).to be_truthy
          end
        end

        it "should have a new tax household with the same aptc data" do
          if tax_household_db
            updated_tax_household = tax_household_db.household.latest_active_tax_households.first
            expect(updated_tax_household).to be_truthy
            expect(updated_tax_household.primary_applicant.family_member.person).to eq person
            expect(updated_tax_household.allocated_aptc).to eq 0
            expect(updated_tax_household.is_eligibility_determined).to be_truthy
            expect(updated_tax_household.current_max_aptc).to eq max_aptc
            expect(updated_tax_household.effective_ending_on).not_to be_truthy
          end
        end
      end
    end
  end
end
