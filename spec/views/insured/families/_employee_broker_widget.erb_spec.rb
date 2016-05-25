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

    # let!(:family) do
    #   f = FactoryGirl.build(:family)
    #   f.family_members = [
    #     FactoryGirl.build(:family_member, family: f, person: person, is_primary_applicant: true)
    #   ]
    #   f.broker_agency_accounts = [
    #     FactoryGirl.build(:broker_agency_account, family: f)
    #   ]
    #   f.save
    #   wa = f.broker_agency_accounts.first.writing_agent.person
    #   wa.emails = [
    #     FactoryGirl.build(:email, kind: "work")
    #   ]
    #   wa.save
    #   f
    # end
    # let(:family_member) { family.family_members.last }

    before :each do
      assign(:person, person)
      assign(:employee_role, employee_role)
      # assign :family_members, [family_member]
      render 'insured/families/employee_brokers_widget'
    end



    it "should display broker widget for consumer" do
      expect(rendered).to have_selector('h4', "Your Broker")
    end

    it "should display brokers email" do
      expect(rendered).to match("mailto")
    end
  end

end
