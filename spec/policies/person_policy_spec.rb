require "rails_helper"

describe PersonPolicy do
  let(:person){FactoryGirl.create(:person, user: user)}
  let(:user){FactoryGirl.create(:user)}
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person)}
  let(:policy){PersonPolicy.new(user,person)}
  let(:hbx_profile) {FactoryGirl.create(:hbx_profile)}
  Permission.all.delete	


  context 'hbx_staff_role subroles' do
    it 'hbx_staff' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_staff))
      expect(policy.updateable?).to be true
    end

    it 'hbx_read_only' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_read_only))
      expect(policy.updateable?).to be true
    end

    it 'hbx_csr_supervisor' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_supervisor))
       expect(policy.updateable?).to be true
    end

    it 'hbx_csr_tier2' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_tier2))
      expect(policy.updateable?).to be true
    end

    it 'csr_tier1' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :hbx_csr_tier1))
      expect(policy.updateable?).to be true 
    end

    it 'developer' do 
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryGirl.create(:permission, :developer))
      expect(policy.updateable?).to be false 
    end

  end
end

