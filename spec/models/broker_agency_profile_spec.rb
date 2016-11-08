require 'rails_helper'

RSpec.describe BrokerAgencyProfile, dbclean: :after_each do
  it { should validate_presence_of :market_kind }
#  it { should validate_presence_of :primary_broker_role_id }

  it { should delegate_method(:hbx_id).to :organization }
  it { should delegate_method(:legal_name).to :organization }
  it { should delegate_method(:dba).to :organization }
  it { should delegate_method(:fein).to :organization }
  it { should delegate_method(:is_active).to :organization }
  it { should delegate_method(:updated_by).to :organization }


  let(:organization) {FactoryGirl.create(:organization)}
  let(:market_kind) {"both"}
  let(:bad_market_kind) {"commodities"}
  let(:primary_broker_role) { FactoryGirl.create(:broker_role) }

  let(:market_kind_error_message) {"#{bad_market_kind} is not a valid practice area"}


  describe ".new" do
    let(:valid_params) do
      {
        organization: organization,
        market_kind: market_kind,
        entity_kind: "s_corporation",
        primary_broker_role: primary_broker_role
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(BrokerAgencyProfile.new(**params).save).to be_falsey
      end
    end

    context "with no organization" do
      let(:params) {valid_params.except(:organization)}

      it "should raise" do
        expect{BrokerAgencyProfile.new(**params).save}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no market_kind" do
      let(:params) {valid_params.except(:market_kind)}

      it "should fail validation" do
        expect(BrokerAgencyProfile.create(**params).errors[:market_kind].any?).to be_truthy
      end
    end

   context "with invalid market_kind" do
      let(:params) {valid_params.deep_merge({market_kind: bad_market_kind})}

      it "should fail validation" do
        expect(BrokerAgencyProfile.create(**params).errors[:market_kind]).to eq [market_kind_error_message]
      end
    end
=begin
    context "with no primary_broker" do
      let(:params) {valid_params.except(:primary_broker_role)}

      it "should fail validation" do
        expect(BrokerAgencyProfile.create(**params).errors[:primary_broker_role_id].any?).to be_truthy
      end
    end
=end

    context "with all valid arguments" do
      let(:params) {valid_params}
      let(:broker_agency_profile) {BrokerAgencyProfile.new(**params)}

      it "should save" do
        expect(broker_agency_profile.save!).to be_truthy
      end

      context "and it is saved" do
        before do
          broker_agency_profile.save
        end

        it "should be findable by id" do
          expect(BrokerAgencyProfile.find(broker_agency_profile.id).id.to_s).to eq broker_agency_profile.id.to_s
        end

        context "and it has some employer profile clients" do
          let(:my_client_count)       { 3 }
          let(:broker_agency_account) { BrokerAgencyAccount.new(broker_agency_profile_id: broker_agency_profile.id,
                                          start_on: TimeKeeper.date_of_record, is_active: true)}
          let!(:my_clients)           { FactoryGirl.create_list(:employer_profile, my_client_count,
                                          broker_agency_accounts: [broker_agency_account] )}

          it "should find all my active employer clients" do
            expect(broker_agency_profile.employer_clients.to_a.size).to eq my_client_count
          end

          it "should return employer profile objects" do
            expect(broker_agency_profile.employer_clients.first).to be_a EmployerProfile
          end
        end

        context "and additional brokers apply join the agency" do
          let(:added_broker_count)         { 5 }
          let!(:added_broker_roles)        { FactoryGirl.create_list(:broker_role, added_broker_count,
                                            broker_agency_profile: broker_agency_profile) }

          it "should find all the new broker roles as candidates" do
            expect(broker_agency_profile.candidate_broker_roles.size).to eq added_broker_count
          end

          context "and all but one are approved by the HBX" do
            let(:last_added_broker_index)   { added_broker_count - 1 }
            before do
              added_broker_roles[0..(last_added_broker_index - 1)].each { |broker| broker.approve! }
              added_broker_roles[last_added_broker_index].deny!
            end

            it "should transition the one broker to denied status" do
              expect(broker_agency_profile.inactive_broker_roles.size).to eq 1
            end

            it "should advance the HBX-approved brokers" do
              expect(broker_agency_profile.candidate_broker_roles.size).to eq (added_broker_count - 1)
              expect(broker_agency_profile.candidate_broker_roles.first.aasm_state).to eq "broker_agency_pending"
            end

            context "and one of the brokers is declined by the broker agency" do
              before do
                broker_agency_profile.candidate_broker_roles.last.broker_agency_decline!
              end

              it "should transition that one broker to denied status" do
                expect(broker_agency_profile.inactive_broker_roles.size).to eq 2
              end
            end

            context "and the remaining brokers are accepted by the broker agency" do
              before do
                remaining_broker_role_count = broker_agency_profile.candidate_broker_roles.size
                broker_agency_profile.candidate_broker_roles[0..(remaining_broker_role_count - 1)].each { |broker| broker.broker_agency_accept! }
              end

              it "should transition the remaining brokers to active status" do
                expect(broker_agency_profile.active_broker_roles.size).to eq (added_broker_count - broker_agency_profile.inactive_broker_roles.size)
              end
            end
          end
        end
      end
    end
  end
  describe "#phone for broker agency" do
    before :each, :dbclean => :after_each  do
      @ba = FactoryGirl.create(:broker_agency).broker_agency_profile
    end
    it 'should have a phone' do
      expect(@ba.phone).to match(@ba.organization.primary_office_location.phone.to_s)
    end
  end
  describe "#families" do
    let(:broker_agency_profile) { FactoryGirl.build(:broker_agency_profile) }
    let(:writing_agent)         { FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile.id) }
    let(:broker_agency_profile2) { FactoryGirl.build(:broker_agency_profile) }
    let(:writing_agent2)         { FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile2.id) }
    let(:person) { FactoryGirl.create(:person)}
    let(:family1) {FactoryGirl.create(:family,:with_primary_family_member, e_case_id: rand(10000), person:person)}
    let(:family2) {FactoryGirl.create(:family,:with_primary_family_member, e_case_id: rand(10000))}
    let(:organization) {FactoryGirl.create(:organization, fein: 333000535 + rand(1000))}

    it "should find a consumer family" do
      family1.hire_broker_agency(writing_agent.id)
      family2.hire_broker_agency(writing_agent2.id)
      expect(broker_agency_profile.families.count).to be(1)
    end
    it "should find the specific consumer family" do
      family1.hire_broker_agency(writing_agent.id)
      family2.hire_broker_agency(writing_agent.id)
      expect(broker_agency_profile.families.count).to be(2)
    end
    it "should find a linked employee" do
      employer = organization.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile)
      employee_role = FactoryGirl.create(:employee_role, person: person, employer_profile: employer)
      expect(broker_agency_profile.linked_employees.count).to eq(1)
    end
    it "should find  linked family" do
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:has_active_employee_role?).and_return(true)
      allow(person).to receive(:primary_family).and_return(family1)
      expect(broker_agency_profile.linked_employees.count).to eq(1)
      expect(broker_agency_profile.families.count).to eq(1)
    end
    it "should find both consumers and employees" do
      family2.hire_broker_agency(writing_agent.id)
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:has_active_employee_role?).and_return(true)
      allow(person).to receive(:primary_family).and_return(family1)
      expect(broker_agency_profile.families.count).to eq(2)
    end
    it "should find unique consumers and employees" do
      family1.hire_broker_agency(writing_agent.id)
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:primary_family).and_return(family1)
      expect(broker_agency_profile.families.count).to eq(1)
    end
  end
end
