require 'rails_helper'

if ExchangeTestingConfigurationHelper.general_agency_enabled?
describe GeneralAgencyStaffRole, dbclean: :after_each do
  let(:address) {FactoryGirl.build(:address)}
  let(:saved_person) {FactoryGirl.create(:person, addresses: [address])}
  let(:general_agency_profile) {FactoryGirl.create(:general_agency_profile)}
  let(:person0) {FactoryGirl.create(:person)}
  let(:person1) {FactoryGirl.create(:person)}
  let(:npn0) {"7775566"}
  let(:npn1) {"48484848"}

  describe ".new" do
    let(:valid_params) do
      {
        person: saved_person,
        npn: npn0,
        general_agency_profile_id: general_agency_profile.id
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(GeneralAgencyStaffRole.new(**params).save).to be_falsey
      end
    end

    context "with no person" do
      let(:params) {valid_params.except(:person)}

      it "should raise" do
        expect{GeneralAgencyStaffRole.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no npn" do
      let(:params) {valid_params.except(:npn)}

      it "should fail validation" do
        expect(GeneralAgencyStaffRole.create(**params).errors[:npn].any?).to be_truthy
      end
    end

    context "with no general_agency_profile_id" do
      let(:params) {valid_params.except(:general_agency_profile_id)}

      it "should fail validation" do
        expect(GeneralAgencyStaffRole.create(**params).errors[:general_agency_profile_id].any?).to be_truthy
      end
    end

    context "with all required data" do
      let(:staff_role) {GeneralAgencyStaffRole.new(valid_params)}

      it "should save" do
        expect(staff_role.save).to be_truthy
      end

      context "and it is saved" do
        before do
          staff_role.save
        end

        it "should be findable" do
          expect(GeneralAgencyStaffRole.find(staff_role.id).id.to_s).to eq staff_role.id.to_s
        end
      end
    end
  end

  context "aasm" do
    let(:staff_role) { FactoryGirl.create(:general_agency_staff_role) }

    context "applicant?" do
      it "should return true" do
        staff_role.aasm_state = 'applicant'
        expect(staff_role.applicant?).to be_truthy
      end

      it "should return false" do
        staff_role.aasm_state = 'active'
        expect(staff_role.applicant?).to be_falsey
      end
    end

    context "active?" do
      it "should return true" do
        staff_role.aasm_state = 'active'
        expect(staff_role.active?).to be_truthy
      end

      it "should return false" do
        staff_role.aasm_state = 'applicant'
        expect(staff_role.active?).to be_falsey
      end
    end

    context "current_state" do
      it "should return applicant" do
        expect(staff_role.current_state).to eq "Applicant"
      end
    end

    context "state changed to" do
      context "active" do
        it "should update the state of staff role and general_agency_profile to approved" do
          staff_role.approve!
          expect(staff_role.applicant?).to be_falsey
          expect(staff_role.general_agency_profile.applicant?).to be_falsey
        end
      end
      context "denied" do
        it "should update the state of staff role and general_agency_profile to denied" do
          staff_role.deny!
          expect(staff_role.aasm_state).to eq('denied')
          expect(staff_role.general_agency_profile.aasm_state).to eq('is_rejected')
        end
      end
      context "decertify" do
        it "should update the state of staff role and general_agency_profile to denied" do
          staff_role.approve! #change the state to approved
          staff_role.decertify!
          expect(staff_role.aasm_state).to eq('decertified')
          expect(staff_role.general_agency_profile.aasm_state).to eq('is_closed')
        end
      end
    end
  end

  context "instance method" do
    let(:staff_role) { FactoryGirl.create(:general_agency_staff_role) }
    it "parent" do
      expect(staff_role.parent).to eq staff_role.person
    end
  end
end
end
