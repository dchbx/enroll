require 'rails_helper'

describe "shared/_update_browser_warning.html.erb" do
  before :each do
    sign_in(user)
    render 'update_browser_warning'
  end

  context "valid user" do
    let(:user) { FactoryGirl.create(:user, person: person) }
    let(:person) { FactoryGirl.create(:person)}

    it "should display a title" do
      expect(rendered).to have_selector("h1")
    end

    it "should display the browser update mesage" do
      expect(rendered).to have_selector("h4.starter")
    end

    it "should display links to download chrome, safari, and firefox" do
      expect(rendered).to have_selector(".browser-icon", count: 3)
    end

  end

end
