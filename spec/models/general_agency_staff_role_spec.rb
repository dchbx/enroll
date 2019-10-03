require 'rails_helper'

describe GeneralAgencyStaffRole, dbclean: :after_each do
  let(:address) {FactoryBot.build(:address)}
  let!(:saved_person) {FactoryBot.create(:person)}
  let(:person0) {FactoryBot.create(:person)}
  let(:person1) {FactoryBot.create(:person)}
  let!(:general_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_general_organization,
    :with_general_agency_profile, :with_site).profiles.first }
  let(:npn0) {"7775566"}
  let(:npn1) {"48484848"}

  describe ".new" do
    let(:valid_params) do
      {
        person: saved_person,
        npn: npn0,
        benefit_sponsors_general_agency_profile_id: general_agency_profile.id
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

      # it "should raise" do
      #   expect{GeneralAgencyStaffRole.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      # end
    end

    context "with no npn" do
      let(:params) {valid_params.except(:npn)}

      it "should fail validation" do
        expect(GeneralAgencyStaffRole.create(**params).errors[:npn].any?).to be_truthy
      end
    end

    context "with no general_agency_profile_id" do
      let(:params) {valid_params.except(:benefit_sponsors_general_agency_profile_id)}

      it "should fail validation" do
        expect(GeneralAgencyStaffRole.create(**params).errors[:benefit_sponsors_general_agency_profile_id].any?).to be_truthy
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

    describe '.is_primary' do
      let(:staff_role) {GeneralAgencyStaffRole.new(valid_params)}

      it 'new staff_role defaults to false' do
        expect(staff_role.is_primary).to be_falsey
      end
    end
  end

  context "aasm" do
    let(:staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, is_primary: true) }

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
      context "general_agency_pending" do
        it "should update the state of staff role to general_agency_pending" do
          staff_role.update_attributes!(aasm_state: :general_agency_terminated)
          staff_role.general_agency_pending!
          expect(staff_role.aasm_state).to eq('general_agency_pending')
        end
      end
      context "general_agency_terminate" do
        it "should update the state of staff role to general_agency_terminated" do
          staff_role.update_attributes!(aasm_state: :general_agency_pending)
          staff_role.general_agency_terminate!
          expect(staff_role.aasm_state).to eq('general_agency_terminated')
        end
      end
    end
  end

  context "instance method" do
    let(:staff_role) { FactoryBot.create(:general_agency_staff_role) }
    it "parent" do
      expect(staff_role.parent).to eq staff_role.person
    end
  end

  describe ".general_agency_profile" do
    context "with_staff_role" do
      let(:staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id) }
      it "has general_agency_profile" do
        expect(staff_role.general_agency_profile).to eq general_agency_profile
      end
    end
  end

  describe ".has_general_agency_profile?" do
    context "with_staff_role" do
      let(:staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id) }

      it "returns true for has_general_agency_profile?" do
        expect(staff_role.has_general_agency_profile?).to eq true
      end
    end
  end
end
