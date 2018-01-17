require 'rails_helper'

RSpec.describe "_consumer_brokers_widget.html.erb" do

  context 'insured home broker widget as consumer with primary family and broker agency accounts' do
    let!(:consumer_role) { FactoryGirl.create(:consumer_role) }
    let(:person) { consumer_role.person }
    let!(:family) do
      f = FactoryGirl.build(:family)
      f.family_members = [
        FactoryGirl.build(:family_member, family: f, person: person, is_primary_applicant: true)
      ]
      f.broker_agency_accounts = [
        FactoryGirl.build(:broker_agency_account, family: f)
      ]
      f.save
      f
    end
    let(:family_member) { family.family_members.last }

    before :each do
      assign(:person, person)
      assign :family_members, [family_member]
      # allow(person).to receive_message_chain("foo.bar")
      render 'insured/families/consumer_brokers_widget'
    end

    it "should display broker widget for consumer" do
      expect(rendered).to have_selector('h3', "Your Broker")
    end

    it "should display brokers email" do
      expect(rendered).to match("mailto")
    end

  end

  context 'insured home broker widget as consumer without broker agency accounts' do
    let!(:consumer_role) { FactoryGirl.create(:consumer_role) }
    let(:person) { consumer_role.person }
    let!(:family) do
      f = FactoryGirl.build(:family)
      f.family_members = [
        FactoryGirl.build(:family_member, family: f, person: person, is_primary_applicant: true)
      ]
      f.save
      f
    end
    let(:family_member) { family.family_members.last }

    before :each do
      assign(:person, person)
      assign :family_members, [family_member]
      render 'insured/families/consumer_brokers_widget'
    end

    it "should display broker widget for consumer" do
      expect(rendered).to have_selector('h3', "Select a Broker or Assister")
    end

    it "should display get help signing up button" do
      expect(rendered).to have_selector('a', "Get Help Signing Up")
    end

    it "should display get help signing up button" do
      expect(rendered).to have_selector('a', "Find Assistance Another Way")
    end
  end
  context 'insured home broker widget as consumer with broker agency and without broker' do
    let!(:consumer_role) { FactoryGirl.create(:consumer_role) }
    let(:person) { consumer_role.person }
    let!(:family) do
      f = FactoryGirl.build(:family)
      f.family_members = [
        FactoryGirl.build(:family_member, family: f, person: person, is_primary_applicant: true)
      ]
      f.broker_agency_accounts = [
        FactoryGirl.build(:broker_agency_account, family: f, writing_agent_id: nil)
      ]
      f.save
      f
    end
    let(:family_member) { family.family_members.last }

    before :each do
      assign(:person, person)
      assign :family_members, [family_member]
      allow(person).to receive_message_chain("primary_family.current_broker_agency.writing_agent").and_return(nil)
      render 'insured/families/consumer_brokers_widget'
    end

    it "should display broker widget for consumer" do
      expect(rendered).to have_selector('h3', "Select a Broker or Assister")
    end

    it "should display get help signing up button" do
      expect(rendered).to have_selector('a', "Get Help Signing Up")
    end

    it "should display get help signing up button" do
      expect(rendered).to have_selector('a', "Find Assistance Another Way")
    end
  end

end