require 'rails_helper'

describe "employers/broker_agency/_active_broker.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:broker_agency_account) { FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile) }
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }

  before :each do
    sign_in user
    employer_profile.broker_agency_profile = broker_agency_account.broker_agency_profile
    employer_profile.save
    assign(:employer_profile, employer_profile)
    assign(:broker_agency_accounts, employer_profile.broker_agency_accounts)
    allow(view).to receive(:policy_helper).and_return(double('EmployerProfile', updateable?: true))
  end

  context "terminate time" do
    it "set date to current day" do
      link = employers_employer_profile_broker_agency_terminate_path(employer_profile.id, employer_profile.broker_agency_profile.id, termination_date: TimeKeeper.date_of_record, direct_terminate: true)
      render "employers/broker_agency/active_broker", direct_terminate: true
      expect(rendered).to have_link('Terminate Broker', href: link)
    end

    it "set date to the day before current" do
      allow(broker_agency_account).to receive(:start_on).and_return(TimeKeeper.date_of_record - 10.days)

      link = employers_employer_profile_broker_agency_terminate_path(employer_profile.id, employer_profile.broker_agency_profile.id, termination_date: TimeKeeper.date_of_record - 1.day, direct_terminate: true)
      render "employers/broker_agency/active_broker", direct_terminate: true
      expect(rendered).to have_link('Terminate Broker', href: link)
    end
  end

  context "show broker information" do
    before :each do
      @employer_profile = employer_profile
      render "employers/broker_agency/active_broker.html.erb"
    end

    it "should show Broker Agency name" do
      expect(rendered).to have_selector('span', text: broker_agency_account.broker_agency_profile.legal_name)
    end

    it "show should the Broker email" do
      expect(rendered).to match(/#{broker_agency_account.writing_agent.email.address}/)
    end

    it "show should the Broker phone" do
      expect(rendered).to match /#{Regexp.escape(broker_agency_account.writing_agent.phone.to_s)}/
    end

    it "should show the broker assignment date" do
      expect(rendered).to match (broker_agency_account.start_on).strftime("%m/%d/%Y")
    end

    it "should see button of change broker" do
      expect(rendered).to have_selector('a.btn', text: 'Change Broker')
    end
  end

  context "can_change_broker?" do
    let(:person) { FactoryGirl.create(:person) }
    let(:user) { FactoryGirl.create(:user, person: person) }
    context "without broker" do
      before :each do
        user.roles = [:general_agency_staff]
        sign_in user
        @employer_profile = employer_profile
        render "employers/broker_agency/active_broker.html.erb"
      end

      it "should have disabled button" do
        expect(rendered).to have_selector('a.disabled', text: 'Browse Brokers')
      end
    end

    context "without broker" do
      before :each do
        user.roles = [:general_agency_staff]
        sign_in user
        @employer_profile = employer_profile
        render "employers/broker_agency/active_broker.html.erb"
      end

      it "should have disabled button of browser brokers" do
        expect(rendered).to have_selector('a.disabled', text: 'Browse Brokers')
      end

      it "should have disabled button of change broker" do
        expect(rendered).to have_selector('a.disabled', text: 'Change Broker')
      end
    end
  end
end
