require 'rails_helper'

describe BrokerRole, dbclean: :around_each do

  let(:address) {FactoryBot.build(:address)}
  let(:saved_person) {FactoryBot.create(:person, addresses: [address])}
  let(:person0) {FactoryBot.create(:person)}
  let(:person1) {FactoryBot.create(:person)}
  let(:npn0) {"7775566"}
  let(:npn1) {"48484848"}
  let(:provider_kind)  {"broker"}

  # before :all do
  #   @broker_agency_profile = FactoryBot.create(:broker_agency_profile)
  # end


  describe ".new" do
    let(:valid_params) do
      {
          person: saved_person,
          npn: npn0,
          provider_kind: provider_kind
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(BrokerRole.new(**params).save).to be_falsey
      end
    end

    context "with no person" do
      let(:params) {valid_params.except(:person)}

      it "should raise" do
        expect{BrokerRole.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no npn" do
      let(:params) {valid_params.except(:npn)}

      it "should fail validation" do
        expect(BrokerRole.create(**params).errors[:npn].any?).to be_truthy
      end
    end

    context "with no provider_kind" do
      let(:params) {valid_params.except(:provider_kind)}

      it "should fail validation" do
        expect(BrokerRole.create(**params).errors[:provider_kind].any?).to be_truthy
      end
    end

    context "with all required data" do
      let(:broker_role) {saved_person.build_broker_role(valid_params)}

      it "should save" do
        expect(broker_role.save).to be_truthy
      end

      context "and it is saved" do
        before do
          broker_role.save
        end

        it "should be findable" do
          expect(BrokerRole.find(broker_role.id).id.to_s).to eq broker_role.id.to_s
        end
      end
    end

    context "assign to employer" do
      let(:broker_role) { FactoryBot.create(:broker_role, aasm_state: "active") }
      let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile, aasm_state: "is_approved", primary_broker_role: broker_role)}
      let(:general_agency_profile) { FactoryBot.create(:general_agency_profile) }
      let(:employer_profile) { FactoryBot.create(:employer_profile, aasm_state: "registered") }
      let!(:organization) { employer_profile.organization }
      let(:person) { FactoryBot.create(:person)}
      let(:family) { FactoryBot.create(:family, :with_primary_family_member,person: person) }

      before :each do
        employer_profile.broker_agency_accounts.create(broker_agency_profile: broker_agency_profile, writing_agent_id: broker_role.id, start_on: TimeKeeper.date_of_record)
        employer_profile.hire_general_agency(general_agency_profile, broker_role.id, start_on = TimeKeeper.datetime_of_record)
        employer_profile.save!
        family.hire_broker_agency(broker_role.id)
      end

      it "should have employer" do
        expect(employer_profile.active_broker.id).to eq broker_role.person.id
      end

      it "should remove broker from GA, Employer, and families when decertified" do
        expect(employer_profile.active_broker.id).to eq broker_role.person.id
        expect(employer_profile.active_general_agency_account.aasm_state).to eq "active"
        expect(family.current_broker_agency).to be_truthy
        broker_role.decertify!
        expect(EmployerProfile.find(employer_profile.id).active_broker).to eq nil
        expect(EmployerProfile.find(employer_profile.id).active_general_agency_account).to eq nil
        expect(Family.find(family.id).current_broker_agency).to eq nil
      end
    end

    context "validate uniqueness of npn" do
      let!(:broker_person) { FactoryBot.create(:person)}
      let!(:broker_role) {FactoryBot.build(:broker_role, npn: "7775588", person: broker_person, provider_kind: provider_kind)}

      it { should validate_uniqueness_of(:npn) }

      it "validate uniqueness of npn" do
        expect(broker_role.valid?).to be_truthy
      end
    end

    context "a broker registers" do
      let(:person)  { FactoryBot.build(:person) }
      let(:registered_broker_role) { BrokerRole.new(person: person, npn: "2323334", provider_kind: "broker") }

      it "should initialize to applicant state" do
        expect(registered_broker_role.valid?).to be_truthy
        expect(registered_broker_role.aasm_state).to eq "applicant"
      end

      it "should record the transition" do
        expect(registered_broker_role.workflow_state_transitions.size).to eq 1
        expect(registered_broker_role.workflow_state_transitions.first.from_state).to be_nil
        expect(registered_broker_role.workflow_state_transitions.first.to_state).to eq "applicant"
      end

      context "and is approved by the HBX" do
        before do
          allow(registered_broker_role).to receive(:is_primary_broker?).and_return(true)
          registered_broker_role.approve
        end

        it "should transition to active status" do
          expect(registered_broker_role.aasm_state).to eq "active"
        end

        it "should record the transition" do
          expect(registered_broker_role.workflow_state_transitions.size).to eq 2
          expect(registered_broker_role.workflow_state_transitions.last.from_state).to eq "applicant"
          expect(registered_broker_role.workflow_state_transitions.last.to_state).to eq "active"
        end

        context "and is then decertified by the HBX" do
          before do
            registered_broker_role.decertify
          end

          it "should transition to decertified status" do
            expect(registered_broker_role.aasm_state).to eq "decertified"
          end

          it "should record the transition" do
            expect(registered_broker_role.workflow_state_transitions.size).to eq 3
            expect(registered_broker_role.workflow_state_transitions.last.from_state).to eq "active"
            expect(registered_broker_role.workflow_state_transitions.last.to_state).to eq "decertified"
          end

          context "should be able to recertify" do
            before do
              registered_broker_role.recertify
            end

            it "should transition to active status" do
              expect(registered_broker_role.aasm_state).to eq "active"
            end

            it "should record the transition" do
              expect(registered_broker_role.workflow_state_transitions.size).to eq 4
              expect(registered_broker_role.workflow_state_transitions.last.from_state).to eq "decertified"
              expect(registered_broker_role.workflow_state_transitions.last.to_state).to eq "active"
            end
          end
        end
      end

      context "and is denied by the HBX" do

        it "should transition to denied status" do
          registered_broker_role.deny
          expect(registered_broker_role.aasm_state).to eq "denied"
        end

        it "should record the transition" do
          registered_broker_role.deny
          expect(registered_broker_role.workflow_state_transitions.size).to eq 2
          expect(registered_broker_role.workflow_state_transitions.last.from_state).to eq "applicant"
          expect(registered_broker_role.workflow_state_transitions.last.to_state).to eq "denied"
        end

        it 'should transition from application_extended to denied' do
          registered_broker_role.update_attributes(aasm_state: 'application_extended')
          registered_broker_role.deny
        end
      end

      context 'extend broker application' do

        it 'should transition denied broker to application_extended' do
          registered_broker_role.deny!
          registered_broker_role.extend_application!
          expect(registered_broker_role.aasm_state).to eq 'application_extended'
        end

        it 'should transition pending broker to application_extended' do
          allow(registered_broker_role).to receive(:is_primary_broker?).and_return(true)
          registered_broker_role.pending!
          registered_broker_role.extend_application!
          expect(registered_broker_role.aasm_state).to eq 'application_extended'
        end

        it 'should transition application_extended broker to application_extended' do
          allow(registered_broker_role).to receive(:is_primary_broker?).and_return(true)
          registered_broker_role.pending!
          registered_broker_role.extend_application!
          registered_broker_role.extend_application!
          expect(registered_broker_role.aasm_state).to eq 'application_extended'
        end
      end

      context 'broker agency accept' do
        before :each do
          allow(registered_broker_role).to receive(:is_primary_broker?).and_return(true)
        end

        it "should transition from broker_agency_pending to active status" do
          registered_broker_role.pending!
          registered_broker_role.broker_agency_accept!
          expect(registered_broker_role.aasm_state).to eq "active"
        end

        it "should transition from application_extended to active status" do
          registered_broker_role.pending!
          registered_broker_role.extend_application!
          registered_broker_role.broker_agency_accept!
          expect(registered_broker_role.aasm_state).to eq "active"
        end
      end

      context "broker agency pending" do
        before do
          allow(registered_broker_role).to receive(:is_primary_broker?).and_return(true)
          registered_broker_role.pending
        end

        it "should transition to pending status" do
          expect(registered_broker_role.aasm_state).to eq "broker_agency_pending"
        end

        it "should record the transition" do
          expect(registered_broker_role.workflow_state_transitions.size).to eq 2
          expect(registered_broker_role.workflow_state_transitions.last.from_state).to eq "applicant"
          expect(registered_broker_role.workflow_state_transitions.last.to_state).to eq "broker_agency_pending"
        end
      end
    end
  end

  describe BrokerRole, '.find_by_npn', :dbclean => :around_each do
    it 'returns Broker instance for the specified National Producer Number' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind)

      expect(BrokerRole.find_by_npn(npn0).npn).to eq b0.npn
    end
  end

  describe BrokerRole, '.find_by_broker_agency_profile', :dbclean => :around_each do
    before :each do
      @ba = FactoryBot.create(:broker_agency).broker_agency_profile
    end

    it 'returns Broker instance for the specified National Producer Number' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind, broker_agency_profile: @ba)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind, broker_agency_profile: @ba)

      expect(BrokerRole.find_by_broker_agency_profile(@ba).size).to eq 2
      expect(BrokerRole.find_by_broker_agency_profile(@ba).first.broker_agency_profile_id).to eq @ba._id
    end
  end

  # Instance methods
  describe BrokerRole, :dbclean => :around_each do
    before :all do
      @ba = FactoryBot.create(:broker_agency).broker_agency_profile
    end

    it '#broker_agency_profile sets agency' do
      expect(BrokerRole.new(broker_agency_profile: @ba).broker_agency_profile.id).to eq @ba._id
    end

    it '#has_broker_agency_profile? is true when agency is assigned' do
      expect(BrokerRole.new(broker_agency_profile: nil).has_broker_agency_profile?).to be_falsey
      expect(BrokerRole.new(broker_agency_profile: @ba).has_broker_agency_profile?).to be_truthy
    end

    # TODO
    it '#address= and #address sets & gets work address on parent person instance' do
      # address = FactoryBot.build(:address)
      # address.kind = "work"

      # expect(person0.build_broker_role(address: address).address._id).to eq address._id
      # expect(person0.build_broker_role(npn: npn0, provider_kind: provider_kind, address: address).save).to eq true
    end
    context '#email returns work email' do
      person0= FactoryBot.create(:person)
      provider_kind = 'broker'

      b1 = BrokerRole.create(person: person0, npn: 10000000+rand(10000), provider_kind: provider_kind, broker_agency_profile: @ba)
      it "#email returns nil if no work email" do
        expect(b1.email).to be_nil
      end
      it '#email returns an instance of email with kind==work' do
        person0.emails[1].update_attributes(kind: 'work')
        expect(b1.email).to be_an_instance_of(Email)
        expect(b1.email.kind).to eq('work')
      end
    end
    context '#phone returns broker office phone or agency office phone or work phone' do
      # broker will not be able to add any work phone.
      person0= FactoryBot.create(:person)
      provider_kind = 'broker'

      it 'should return broker agency profile phone' do
        b1 = BrokerRole.create(person: person0, npn: 10000000+rand(10000), provider_kind: provider_kind, broker_agency_profile: @ba)
        expect(b1.phone.to_s).to eq b1.broker_agency_profile.phone
      end
      it 'should return work phone' do
        b1 = BrokerRole.create(person: person0, npn: 10000000+rand(10000), provider_kind: provider_kind, broker_agency_profile: @ba)
        person0.phones[1].update_attributes!(kind: 'work')
        expect(b1.phone.to_s).not_to eq b1.broker_agency_profile.phone
        expect(b1.phone.to_s).to eq person0.phones.where(kind: "work").first.to_s
      end

      it 'should return work phone if office phone & broker agency profile phone not present' do
        b1 = BrokerRole.create(person: person0, npn: 10000000+rand(10000), provider_kind: provider_kind, broker_agency_profile: @ba)
        allow(b1.broker_agency_profile).to receive(:phone).and_return nil
        person0.phones[1].update_attributes!(kind: 'work')
        expect(b1.phone.to_s).not_to eq b1.broker_agency_profile.phone
        expect(b1.phone.to_s).to eq person0.phones.where(kind: "work").first.to_s
      end
    end
  end
end
