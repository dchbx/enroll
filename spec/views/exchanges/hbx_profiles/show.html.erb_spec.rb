require 'rails_helper'
include Pundit

RSpec.describe "exchanges/hbx_profiles/show.html.erb", :type => :view do

  describe "a signed in admin user" do
    let(:user) { FactoryGirl.create(:user, person: person)}
    let(:person) {FactoryGirl.create(:person, :with_employee_role) }

    before :each do
      sign_in user
    end
    it "does not show general agency related links" do
      render
      expect(rendered).not_to match /General Agency/
    end
  end

end
