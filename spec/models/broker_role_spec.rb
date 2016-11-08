require 'rails_helper'

describe BrokerRole, dbclean: :after_each do

  let(:address) {FactoryGirl.build(:address)}
  let(:saved_person) {FactoryGirl.create(:person, addresses: [address])}
  let(:person0) {FactoryGirl.create(:person)}
  let(:person1) {FactoryGirl.create(:person)}
  let(:npn0) {"7775566"}
  let(:npn1) {"48484848"}
  let(:provider_kind)  {"broker"}

  # before :all do
  #   @broker_agency_profile = FactoryGirl.create(:broker_agency_profile)
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

    context "with duplicate npn number" do
      let(:params) {valid_params}

      it "should raise" do
        expect(BrokerRole.with(safe: true).create(**params)).to be_truthy

        ## TODO: Change this to proper Error when Mongoid is coerced into raising it
        # expect{BrokerRole.with(safe: true).create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "a broker registers" do
      let(:person)  { FactoryGirl.build(:person) }
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

          it "should transition to active status" do
            expect(registered_broker_role.aasm_state).to eq "decertified"
          end

          it "should record the transition" do
            expect(registered_broker_role.workflow_state_transitions.size).to eq 3
            expect(registered_broker_role.workflow_state_transitions.last.from_state).to eq "active"
            expect(registered_broker_role.workflow_state_transitions.last.to_state).to eq "decertified"
          end
        end
      end

      context "and is denied by the HBX" do
        before do
          registered_broker_role.deny
        end

        it "should transition to active status" do
          expect(registered_broker_role.aasm_state).to eq "denied"
        end

        it "should record the transition" do
          expect(registered_broker_role.workflow_state_transitions.size).to eq 2
          expect(registered_broker_role.workflow_state_transitions.last.from_state).to eq "applicant"
          expect(registered_broker_role.workflow_state_transitions.last.to_state).to eq "denied"
        end
      end
    end
  end

  describe BrokerRole, '.find', :dbclean => :after_each do
    it 'returns Broker instance for the specified ID' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)

      expect(BrokerRole.find(b0._id)).to be_an_instance_of BrokerRole
      expect(BrokerRole.find(b0._id).npn).to eq b0.npn
    end
  end

  describe BrokerRole, '.all', :dbclean => :after_each do
    it 'returns all Broker instances' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind)

      # expect(BrokerRole.all).to be_an_instance_of Mongoid::Criteria
      expect(BrokerRole.all.last).to be_an_instance_of BrokerRole
      expect(BrokerRole.all.size).to eq 2
    end
  end

  describe BrokerRole, '.find_by_npn', :dbclean => :after_each do
    it 'returns Broker instance for the specified National Producer Number' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind)

      expect(BrokerRole.find_by_npn(npn0).npn).to eq b0.npn
    end
  end

  describe BrokerRole, '.find_by_broker_agency_profile', :dbclean => :after_each do
    before :each do 
      @ba = FactoryGirl.create(:broker_agency).broker_agency_profile
    end

    it 'returns Broker instance for the specified National Producer Number' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind, broker_agency_profile: @ba)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind, broker_agency_profile: @ba)

      expect(BrokerRole.find_by_broker_agency_profile(@ba).size).to eq 2
      expect(BrokerRole.find_by_broker_agency_profile(@ba).first.broker_agency_profile_id).to eq @ba._id
    end
  end

  describe BrokerRole, '.all', :dbclean => :after_each do
    it 'returns all Broker instances' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind)

      # expect(BrokerRole.all).to be_an_instance_of Mongoid::Criteria
      expect(BrokerRole.all.last).to be_an_instance_of BrokerRole
      expect(BrokerRole.all.size).to eq 2
    end
  end

  # Instance methods
  describe BrokerRole, :dbclean => :around_each do
    before :all do 
      @ba = FactoryGirl.create(:broker_agency).broker_agency_profile
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
      # address = FactoryGirl.build(:address)
      # address.kind = "work"

      # expect(person0.build_broker_role(address: address).address._id).to eq address._id
      # expect(person0.build_broker_role(npn: npn0, provider_kind: provider_kind, address: address).save).to eq true
    end
    context '#email returns work email' do
      person0= FactoryGirl.create(:person)
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
    context '#phone returns broker work phone or agency office phone' do
      person0= FactoryGirl.create(:person)
      provider_kind = 'broker'

      it 'should return broker agency profile phone' do
        b1 = BrokerRole.create(person: person0, npn: 10000000+rand(10000), provider_kind: provider_kind, broker_agency_profile: @ba)
        expect(b1.phone.to_s).to eq b1.broker_agency_profile.phone
      end
      it 'should return broker person work phone' do
        b1 = BrokerRole.create(person: person0, npn: 10000000+rand(10000), provider_kind: provider_kind, broker_agency_profile: @ba)
        person0.phones[1].update_attributes!(kind: 'work')
        expect(b1.phone.to_s).not_to eq b1.broker_agency_profile.phone
        expect(b1.phone.to_s).to eq person0.phones[1].to_s
      end
    end
  end
end
