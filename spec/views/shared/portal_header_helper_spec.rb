require 'rails_helper'

  RSpec.configure do |c|
    c.include PortalHeaderHelper
  end

  RSpec.describe "Builds user with correct role" do
    let(:employer_profile){ FactoryGirl.build(:employer_profile) }
    let(:employer_profile2){ FactoryGirl.build(:employer_profile) }
    let(:employer_staff_role){ FactoryGirl.create(:employer_staff_role, aasm_state:'is_closed',:employer_profile_id=>employer_profile.id)}
    let(:employer_staff_role2){ FactoryGirl.create(:employer_staff_role,aasm_state:'is_active',:employer_profile_id=>employer_profile2.id)}
    let(:this_person) { FactoryGirl.build(:person, :employer_staff_roles => [employer_staff_role, employer_staff_role2]) }
    let(:current_user) { FactoryGirl.build(:user, :person=>this_person)}
    let(:signed_in?){ true }
    let(:emp_id) {current_user.person.active_employer_staff_roles.first.employer_profile_id}

    before(:each) do
    	sign_in current_user
    end

    it "returns I'm an Employer is user has correct role" do
      expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/employers/employer_profiles/"+ emp_id.to_s + "\"><img src=\"/images/icons/icon-business-owner.png\" alt=\"Icon business owner\" /> &nbsp; I'm an Employer</a>"
    end

    it "returns Welcome prompt if user doesnt have correct role" do
      allow(current_user).to receive(:has_employer_staff_role?).and_return(false)
      expect(portal_display_name(controller)).to eq "<a class='portal'>Welcome to the District's Health Insurance Marketplace</a>"
    end
  end