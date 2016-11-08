require 'rails_helper'

describe "exchanges/agents/home.erb" do
    let(:person) { FactoryGirl.create(:person)}
    let(:csr_role) {FactoryGirl.build(:csr_role, cac: false)}
    let(:cac_role) {FactoryGirl.build(:csr_role, cac: true)}
    let(:current_user) { FactoryGirl.create(:user, :person => person)}
    before :each do
      stub_template "exchanges/agents/_primary_nav.html.erb"  => 'nav_bar'
      @title = 'CAC or Assister'
      allow(current_user).to receive(:person).and_return(person)
    end

    it "renders the CSR template for CSRs" do

      person.csr_role = csr_role
      current_user.save
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      
      sign_in(current_user)
      render template: "/exchanges/agents/home", :active_tab => "home-tab"
      expect(rendered).not_to have_text(@title)
      expect(rendered).to have_text(/nav_bar/)
    end

    it "renders the agent page for CAC" do
      person.csr_role = cac_role
      current_user.save
      sign_in(current_user)
      render template: "/exchanges/agents/home", :active_tab => "home-tab"
      expect(rendered).to have_text(@title)
      expect(rendered).to have_text("Messages")
      expect(rendered).to have_text("Inbox: FROM")
      expect(rendered).not_to have_text(/nav_bar/)
    end

    it "renders the agent page for Asssiter" do
      person.csr_role = false
      current_user.save
      sign_in(current_user)
      render template: "/exchanges/agents/home", :active_tab => "home-tab"
      expect(rendered).to have_text(@title)
      expect(rendered).to have_text("Messages")
      expect(rendered).to have_text("Inbox: FROM")
      expect(rendered).not_to have_text(/nav_bar/)
    end

end
