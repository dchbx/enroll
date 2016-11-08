require 'rails_helper'

describe "insured/families/inbox.html.erb" do
  let(:user) { FactoryGirl.build_stubbed(:user, person: person) }
  let(:person) { FactoryGirl.build_stubbed(:person) }

  before :each do
    sign_in(user)
    assign(:person, person)
    assign(:current_user, user)
    assign(:provider, person)
    allow(person).to receive_message_chain("inbox.unread_messages.size").and_return(3)
  end

  context "as admin" do
    before do
      allow(view).to receive_message_chain("current_user.has_hbx_staff_role?").and_return(true)
      render template: "insured/families/inbox.html.erb"
    end

    it "should display the upload notices button" do
      expect(rendered).to match(/upload notices/i)
    end
  end

  context "as insured" do
    before do
      allow(view).to receive_message_chain("current_user.has_hbx_staff_role?").and_return(false)
      render template: "insured/families/inbox.html.erb"
    end

    it "should not display the upload notices button" do
      expect(rendered).to_not match(/upload notices/i)
    end
  end
end