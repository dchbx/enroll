require 'rails_helper'

RSpec.describe "_employee_brokers_widget.html.erb" do

  context 'insured home broker widget as employee' do
    let!(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:person) { employee_role.person }
    let!(:employer_profile) do
      ep = employee_role.employer_profile
      ep.broker_agency_accounts = [
        FactoryGirl.build(:broker_agency_account, employer_profile: ep)
      ]
      ep.save
      ep
    end

    before :each do
      assign(:person, person)
      assign(:employee_role, employee_role)
      # assign :family_members, [family_member]
      render 'insured/families/employee_brokers_widget', title: nil
    end

    it "should display broker widget for consumer" do
      expect(rendered).to have_selector('h3', "Your Broker")
    end

    it "should display brokers email" do
      expect(rendered).to match("mailto")
    end
  end

  context 'insured home broker widget as employee without selected broker' do
    let!(:employee_role) { FactoryGirl.create(:employee_role) }
    let!(:broker_agency_profile) { FactoryGirl.build_stubbed(:broker_agency_profile) }
    let(:person) { employee_role.person }
    let!(:employer_profile) do
      ep = employee_role.employer_profile
      ep.broker_agency_accounts = [
        FactoryGirl.build(:broker_agency_account, employer_profile: ep)
      ]
      ep.save
      ep
    end

    before :each do
      assign(:person, person)
      assign(:employee_role, employee_role)
      allow(employee_role).to receive_message_chain("employer_profile.active_broker_agency_account.present?").and_return(false)
      allow(employee_role).to receive_message_chain("employer_profile.broker_agency_profile").and_return(broker_agency_profile)
    end

    it "should not display brokers email or widget" do
      render 'insured/families/employee_brokers_widget', title: nil
      expect(rendered).to_not match("mailto")
    end

  end

end
