require 'rails_helper'

module BenefitSponsors
  RSpec.describe Organizations::HbxProfile, type: :model, :dbclean => :after_each do
    
    describe "#find" do
    	let(:subject) { BenefitSponsors::Organizations::HbxProfile }
    	let(:hbx_profile) { FactoryBot.create(:benefit_sponsors_organizations_hbx_profile )}
    	let(:hbx_profile_id) {hbx_profile.id}

    	it 'should find hbx profile and return it' do
    		expect(subject.find(hbx_profile_id)).to eq hbx_profile
    	end
	end
  end
end
