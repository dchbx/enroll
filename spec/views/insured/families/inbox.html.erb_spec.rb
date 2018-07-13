require 'rails_helper'

describe "insured/families/inbox.html.erb", dbclean: :after_each do
  let(:user) { FactoryGirl.build_stubbed(:user, person: person) }
  let(:person) { FactoryGirl.create(:person) }
  let(:consumer_role) { double('consumer_role', :is_active? => true)}
  let(:individual_market_is_enabled) { true }

  before :each do
    sign_in(user)
    assign(:person, person)
    assign(:current_user, user)
    assign(:provider, person)
    allow(person).to receive_message_chain("inbox.unread_messages.size").and_return(3)
  end

  context "as admin" do
    before :each do
      allow(view).to receive_message_chain("current_user.has_hbx_staff_role?").and_return(true)
    end

    it "should display the upload notices button" do
      render template: "insured/families/inbox.html.erb"
      expect(rendered).to match(/upload notices/i)
    end

    it "should display the download tax documents button if consumer has SSN" do
      allow(person).to receive(:consumer_role).and_return consumer_role
      stub_template "insured/families/_navigation.html.erb" => ""
      allow(person).to receive(:ssn).and_return '123456789'
      render template: "insured/families/inbox.html.erb"
      expect(rendered).to match(/Download Tax Documents/i)
    end

    it "should not display the download tax documents button if consumer has no SSN" do
      allow(person).to receive(:consumer_role).and_return consumer_role
      stub_template "insured/families/_navigation.html.erb" => ""
      render template: "insured/families/inbox.html.erb"
      expect(rendered).not_to match(/Download Tax Documents/i)
    end

    it "should not display the download tax documents button for employee with ssn and without consumer" do
      allow(person).to receive(:ssn).and_return '123456789'
      render template: "insured/families/inbox.html.erb"
      expect(rendered).not_to match(/Download Tax Documents/i)
    end

    it "should not display the download tax documents button for employee without ssn and consumer" do
      render template: "insured/families/inbox.html.erb"
      expect(rendered).not_to match(/Download Tax Documents/i)
    end

    it "should not display the download tax documents button if person is both consumer and employee without ssn" do
      allow(person).to receive(:consumer_role).and_return consumer_role
      stub_template "insured/families/_navigation.html.erb" => ""
      render template: "insured/families/inbox.html.erb"
      expect(rendered).not_to match(/Download Tax Documents/i)
    end

    it "should display the download tax documents button if person is both consumer IVL and employee" do
      allow(person).to receive(:consumer_role).and_return consumer_role
      stub_template "insured/families/_navigation.html.erb" => ""
      allow(person).to receive(:ssn).and_return '123456789'
      render template: "insured/families/inbox.html.erb"
      expect(rendered).to match(/Download Tax Documents/i)
    end
  end

  context "as consumer" do
    before do
      allow(view).to receive_message_chain("current_user.has_hbx_staff_role?").and_return(false)
      allow(view).to receive(:individual_market_is_enabled?).and_return(individual_market_is_enabled)
      allow(person).to receive(:consumer_role).and_return consumer_role
      stub_template "insured/families/_navigation.html.erb" => ""
    end

    it "should not display the upload notices button" do
      render template: "insured/families/inbox.html.erb"
      expect(rendered).to_not match(/upload notices/i)
    end

    it "should display the download tax documents button if consumer has SSN" do
      allow(person).to receive(:ssn).and_return '123456789'
      render template: "insured/families/inbox.html.erb"
      expect(rendered).to match(/Download Tax Documents/i)
    end

    it "should not display the download tax documents button if consumer has no SSN" do
      render template: "insured/families/inbox.html.erb"
      expect(rendered).to_not match(/Download Tax Documents/i)
    end

    it "should display the download tax documents button if person is both consumer and employee" do
      allow(person).to receive(:ssn).and_return '123456789'
      render template: "insured/families/inbox.html.erb"
      expect(rendered).to match(/Download Tax Documents/i)
    end

    it "should not display the download tax documents button if person is both consumer and employee without ssn" do
      render template: "insured/families/inbox.html.erb"
      expect(rendered).not_to match(/Download Tax Documents/i)
    end

    context "for Curam Navigation" do

      before :each do
        render template: "insured/families/inbox.html.erb"
      end

      it "should verify if the LEFT text exists on the page" do
        expect(rendered).to have_content("If you applied for Medicaid and tax credit savings, view additional messages")
      end

      it "should verify if the Curam navigation link exists on the page" do
        expect(rendered).to have_link('Medicaid & Tax Credits')
      end
    end
  end

  context "as employee" do
    before :each do
      allow(view).to receive_message_chain("current_user.has_hbx_staff_role?").and_return(false)
    end

    it "should display not the upload notices button" do
      render template: "insured/families/inbox.html.erb"
      expect(rendered).to_not match(/upload notices/i)
    end

    it "should not display the download tax documents button for employee with ssn" do
      allow(person).to receive(:ssn).and_return '123456789'
      render template: "insured/families/inbox.html.erb"
      expect(rendered).not_to match(/Download Tax Documents/i)
    end

    it "should not display the download tax documents button for employee with out ssn" do
      render template: "insured/families/inbox.html.erb"
      expect(rendered).not_to match(/Download Tax Documents/i)
    end
  end
end
