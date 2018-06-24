require 'rails_helper'

RSpec.describe "welcome/index.html.slim", :type => :view do
  it "should has current_user oim_id" do
    user = FactoryGirl.create(:user, oim_id: "test@enroll.com")
    sign_in user
    render

    expect(rendered).to match /#{user.oim_id}/
  end
end
