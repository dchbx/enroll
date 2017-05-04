require 'rails_helper'

RSpec.describe "welcome/index.html.erb", :type => :view do
  it "should has current_user oim_id" do
    user = FactoryGirl.create(:user, oim_id: "test@enroll.com")
    sign_in user
    render

    expect(rendered).to match /#{user.oim_id}/
  end

  describe "Enabled/Disabled IVL market" do
  	shared_examples_for "IVL market status" do |status, value|
		  it "should #{status} Consumer/Family Portal registeration" do
		  	if value == false
					expect(rendered).not_to have_link('Consumer/Family Portal')
				else
					expect(rendered).to have_link('Consumer/Family Portal')
				end
		  end

		  it "should #{status} Assisted Consumer/Family Portal registeration" do
		  	if value == false
					expect(rendered).not_to have_link('Assisted Consumer/Family Portal')
				else
					expect(rendered).to have_link('Assisted Consumer/Family Portal')
				end
		  end
		end

		# it_behaves_like "IVL market status", "Enable", Settings.aca.market_kinds.include? "individual" # use it when we enable IVL market
		it_behaves_like "IVL market status", "Disabled", Settings.aca.market_kinds.include?("individual")
  end
end