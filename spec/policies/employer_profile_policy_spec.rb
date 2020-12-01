require "rails_helper"

describe EmployerProfilePolicy, dbclean: :after_each do
  let(:person){FactoryBot.create(:person, user: user)}
  let(:user){FactoryBot.create(:user)}
  let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
  let(:policy){EmployerProfilePolicy.new(user,FactoryBot.create(:employer_profile))}
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}

  context 'hbx_staff_role subroles' do
    it 'hbx_staff' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_staff))
      expect(policy.list_enrollments?).to be true
      expect(policy.updateable?).to be true
      expect(policy.revert_application?).to be true
    end

    it 'hbx_read_only' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_read_only))
      expect(policy.list_enrollments?).to be true
      expect(policy.updateable?).to be false
      expect(policy.revert_application?).to be false
      expect(policy.can_access_pay_now?).to be true
    end

    it 'hbx_csr_supervisor' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_supervisor))
      expect(policy.list_enrollments?).to be true
      expect(policy.updateable?).to be true
      expect(policy.revert_application?).to be true
    end

    it 'hbx_csr_tier2' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_tier2))
      expect(policy.list_enrollments?).to be false
      expect(policy.updateable?).to be true
      expect(policy.revert_application?).to be false
    end

    it 'csr_tier1' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_tier1))
      expect(policy.list_enrollments?).to be false
      expect(policy.updateable?).to be false
      expect(policy.revert_application?).to be false
      expect(policy.can_access_pay_now?).to be true
    end

  end
end
