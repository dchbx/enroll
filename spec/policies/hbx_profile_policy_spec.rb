require "rails_helper"

describe HbxProfilePolicy do
  subject { described_class }
  let(:hbx_profile){ hbx_staff_person.hbx_staff_role.hbx_profile }
  let(:hbx_staff_person) { FactoryGirl.create(:person, :with_hbx_staff_role) }
  let(:assister_person) { FactoryGirl.create(:person, :with_assister_role) }
  let(:csr_person) { FactoryGirl.create(:person, :with_csr_role) }
  let(:employee_person) { FactoryGirl.create(:person, :with_employee_role)}

  permissions :show? do
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryGirl.build(:user, :hbx_staff, person: hbx_staff_person), HbxProfile)
    end

    it "grants access when csr" do
      expect(subject).to permit(FactoryGirl.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "grants access when assister" do
      expect(subject).to permit(FactoryGirl.build(:user, :assister, person: assister_person), HbxProfile)
    end

    it "denies access when employee" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :employee, person: employee_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :index? do
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryGirl.build(:user, :hbx_staff, person: hbx_staff_person), HbxProfile)
    end

    it "denies access when csr" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :edit? do
    it "denies access when csr" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end

    context "when hbx_staff" do
      let(:user) { FactoryGirl.create(:user, :hbx_staff, person: hbx_staff_person) }

      it "grants access" do
        expect(subject).to permit(user, hbx_profile)
      end

      it "denies access" do
        expect(subject).not_to permit(user, HbxProfile.new)
      end
    end
  end
end
describe HbxProfilePolicy do
  let(:person){FactoryGirl.create(:person, user: user)}
  let(:user){FactoryGirl.create(:user)}
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person)}
  let(:policy){HbxProfilePolicy.new(user,hbx_profile)}
  let(:hbx_profile) {FactoryGirl.create(:hbx_profile)}
  Permission.all.delete

  context 'hbx_staff_role subroles' do
    it 'hbx_staff' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_staff))
      expect(policy.modify_admin_tabs?).to be true
      expect(policy.view_admin_tabs?).to be true
      expect(policy.send_broker_agency_message?).to be true
      expect(policy.approve_broker?).to be true
      expect(policy.approve_ga?).to be true
    end

    it 'hbx_read_only' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_read_only))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be true
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
    end

    it 'hbx_csr_supervisor' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_supervisor))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
    end

    it 'hbx_csr_tier2' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_tier2))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
    end

    it 'csr_tier1' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_tier1))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
    end

  end
end