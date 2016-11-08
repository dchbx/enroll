require "rails_helper"

describe EmployerProfilePolicy do
  let(:person){FactoryGirl.create(:person, user: user)}
  let(:user){FactoryGirl.create(:user)}
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person)}
  let(:policy){EmployerProfilePolicy.new(user,FactoryGirl.create(:employer_profile))}
  let(:hbx_profile) {FactoryGirl.create(:hbx_profile)}
  Permission.all.delete	

  context 'hbx_staff_role subroles' do
    it 'hbx_staff' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_staff))
      expect(policy.list_enrollments?).to be true
      expect(policy.updateable?).to be true
      expect(policy.revert_application?).to be true
    end

    it 'hbx_read_only' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_read_only))
      expect(policy.list_enrollments?).to be true
      expect(policy.updateable?).to be false
      expect(policy.revert_application?).to be false
    end

    it 'hbx_csr_supervisor' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_supervisor))
      expect(policy.list_enrollments?).to be true
      expect(policy.updateable?).to be true
      expect(policy.revert_application?).to be true
    end

    it 'hbx_csr_tier2' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_tier2))
      expect(policy.list_enrollments?).to be false
      expect(policy.updateable?).to be true
      expect(policy.revert_application?).to be false
    end

    it 'csr_tier1' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_tier1))
      expect(policy.list_enrollments?).to be false
      expect(policy.updateable?).to be false
      expect(policy.revert_application?).to be false
    end

  end
end







