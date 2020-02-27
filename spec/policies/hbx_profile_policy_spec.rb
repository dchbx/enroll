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

  describe "given an HbxStaffRole with permissions" do
    let(:person){FactoryGirl.create(:person, user: user)}
    let(:user){FactoryGirl.create(:user)}
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person)}
    let(:policy){HbxProfilePolicy.new(user,hbx_profile)}
    let(:hbx_profile) {FactoryGirl.create(:hbx_profile)}

    it 'hbx_staff' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_staff))
      expect(policy.modify_admin_tabs?).to be true
      expect(policy.view_admin_tabs?).to be true
      expect(policy.send_broker_agency_message?).to be true
      expect(policy.approve_broker?).to be true
      expect(policy.approve_ga?).to be true
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
    end

    it 'hbx_read_only' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_read_only))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be true
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
    end

    it 'hbx_csr_supervisor' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_supervisor))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
    end

    it 'hbx_csr_tier2' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_tier2))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
    end

    it 'csr_tier1' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_tier1))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
    end

    it 'super_admin' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :super_admin))
      expect(policy.modify_admin_tabs?).to be true
      expect(policy.view_admin_tabs?).to be true
      expect(policy.send_broker_agency_message?).to be true
      expect(policy.approve_broker?).to be true
      expect(policy.approve_ga?).to be true
      expect(policy.can_modify_plan_year?).to be true
    end
  end

  describe "given no staff role" do
    let(:person) { FactoryGirl.create(:person, user: user) }
    let(:user) { FactoryGirl.create(:user) }
    let(:policy) { HbxProfilePolicy.new(user,hbx_profile) }
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }

    before :each do
      person
    end

    it "is prohibited from modifying admin tabs" do
      expect(policy.modify_admin_tabs?).to be false
    end

    it "is prohibited from viewing admin tabs" do
      expect(policy.view_admin_tabs?).to be false
    end

    it "is prohibited from sending broker agency messages" do
      expect(policy.send_broker_agency_message?).to be false
    end

    it "is prohibited from approving brokers" do
      expect(policy.approve_broker?).to be false
    end

    it "is prohibited from approving GAs" do
      expect(policy.approve_ga?).to be false
    end

    it "is prohibited from extending open enrollment" do
      expect(policy.can_extend_open_enrollment?).to be false
    end

    it "is prohibited from extending creating benefit applications" do
      expect(policy.can_create_benefit_application?).to be false
    end

    it "is prohibited from changing feins" do
      expect(policy.can_change_fein?).to be false
    end

    it "is prohibited from force publishing" do
      expect(policy.can_force_publish?).to be false
    end

    it "is prohibited from viewing config tab" do
      expect(policy.view_the_configuration_tab?).to be false
    end

    it "is prohibited from time traveling" do
      expect(policy.can_submit_time_travel_request?).to be false
    end
  end
end

describe HbxProfilePolicy do
  context '.can_create_benefit_application?' do
    let!(:user10)                  { FactoryGirl.create(:user) }
    let!(:person)                  { FactoryGirl.create(:person, :with_hbx_staff_role, user: user10) }

    subject                        { HbxProfilePolicy.new(user10, nil) }


    (Permission::PERMISSION_KINDS - ['super_admin', 'hbx_tier3']).each do |kind|
      context "for permissions which doesn't allow the user" do
        let(:bad_permission) { FactoryGirl.create(:permission, kind.to_sym) }

        it 'should return false' do
          person.hbx_staff_role.update_attributes!(permission_id: bad_permission.id)
          expect(subject.can_create_benefit_application?).to eq false
        end
      end
    end

    ['super_admin', 'hbx_tier3'].each do |kind|
      context "for permissions which doesn't allow the user" do
        let(:good_permission) { FactoryGirl.create(:permission, kind.to_sym) }

        it 'should return true' do
          person.hbx_staff_role.update_attributes!(permission_id: good_permission.id)
          expect(subject.can_create_benefit_application?).to eq true
          expect(subject.can_submit_time_travel_request?).to eq false
        end
      end
    end
  end
    describe HbxProfilePolicy do
      context 'super admin can view config tab?' do
        let!(:user10)                  { FactoryGirl.create(:user) }
        let!(:person)                  { FactoryGirl.create(:person, :with_hbx_staff_role, user: user10) }

        subject                        { HbxProfilePolicy.new(user10, nil) }

      ['super_admin'].each do |kind|
        context "for permissions which doesn't allow the user" do
          let(:good_permission) { FactoryGirl.create(:permission, kind.to_sym) }

          it 'should return true' do
            person.hbx_staff_role.update_attributes!(permission_id: good_permission.id)
            expect(subject.can_create_benefit_application?).to eq true
            expect(subject.can_submit_time_travel_request?).to eq false
            expect(subject.view_the_configuration_tab?).to eq true
          end
        end
      end
    end
  end

end

describe HbxProfilePolicy do
  context '.can_update_enrollment_end_date? .can_reinstate_enrollment?' do
    let!(:user)                  { FactoryGirl.create(:user) }
    let!(:person)                  { FactoryGirl.create(:person, :with_hbx_staff_role, user: user) }

    subject                        { HbxProfilePolicy.new(user, nil) }


    (Permission::PERMISSION_KINDS - ['super_admin', 'hbx_tier3']).each do |kind|
      context "for permissions which doesn't allow the user" do
        let(:bad_permission) { FactoryGirl.create(:permission, kind.to_sym) }

        it 'should return false' do
          person.hbx_staff_role.update_attributes!(permission_id: bad_permission.id)
          expect(subject.can_update_enrollment_end_date?).to eq false
          expect(subject.can_reinstate_enrollment?).to eq false
        end
      end
    end

    ['super_admin', 'hbx_tier3'].each do |kind|
      context "for permissions which allow the user" do
        let(:good_permission) { FactoryGirl.create(:permission, kind.to_sym) }

        it 'should return true' do
          person.hbx_staff_role.update_attributes!(permission_id: good_permission.id)
          expect(subject.can_update_enrollment_end_date?).to eq true
          expect(subject.can_reinstate_enrollment?).to eq true
        end
      end
    end
  end
end

