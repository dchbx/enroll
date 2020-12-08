require 'rails_helper'

# Date.today converted to TimeKeeper.date_of_record

RSpec.describe "views/benefit_sponsors/profiles/employers/broker_agency/_active_broker.html.erb", :type => :view, dbclean: :after_each do

  let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :cca, :with_benefit_market) }
  let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
  let(:employer_profile) { organization.employer_profile }
  let!(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'shop', legal_name: 'Legal Name1', assigned_site: site) }
  let!(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }

  let!(:benefit_sponsorship) {FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_broker_agency_account, profile: employer_profile, broker_agency_profile: broker_agency_profile, benefit_market: site.benefit_markets.first)}
  let!(:broker_agency_account) {benefit_sponsorship.broker_agency_accounts.first}


  let!(:person) { FactoryBot.create(:person) }
  let!(:date) { TimeKeeper.date_of_record - 1.day }
  let!(:user) { FactoryBot.create(:user, person: person) }

  before :each do
    view.extend BenefitSponsors::Engine.routes.url_helpers
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
    sign_in user
    assign(:employer_profile, employer_profile)
    assign(:broker_agency_account, broker_agency_account)
    assign(:broker_agency_accounts, benefit_sponsorship.broker_agency_accounts)
  end

  context "terminate time" do

    it "set date to current day" do
      allow(broker_agency_account).to receive(:start_on).and_return(TimeKeeper.date_of_record)
      render "benefit_sponsors/profiles/employers/broker_agency/active_broker", direct_terminate: true
      expect(rendered).to have_link('Terminate Broker')
    end

    it "set date to the day before current" do
      allow(broker_agency_account).to receive(:start_on).and_return(TimeKeeper.date_of_record - 10.days)
      render "benefit_sponsors/profiles/employers/broker_agency/active_broker", direct_terminate: true
      link = "/benefit_sponsors/profiles/employers/employer_profiles/#{employer_profile.id}/broker_agency/#{employer_profile.broker_agency_profile.id}/terminate?direct_terminate=true&termination_date=#{date.month}%2F#{date.day}%2F#{date.year}"
      expect(rendered).to have_link('Terminate Broker')
    end
  end

  context "show broker information" do
    before :each do
      view.extend BenefitSponsors::Engine.routes.url_helpers
      @employer_profile = employer_profile
      render "benefit_sponsors/profiles/employers/broker_agency/active_broker", direct_terminate: true
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
    let(:person) { FactoryBot.create(:person) }
    let(:user) { FactoryBot.create(:user, person: person) }
    context "without broker" do
      before :each do
        view.extend BenefitSponsors::Engine.routes.url_helpers
        user.roles = [:general_agency_staff]
        sign_in user
        @employer_profile = employer_profile
        render "benefit_sponsors/profiles/employers/broker_agency/active_broker", direct_terminate: true
      end

      it "should have disabled button" do
        expect(rendered).to have_selector('a.disabled', text: 'Browse Brokers')
      end
    end

    context "without broker" do
      before :each do
        view.extend BenefitSponsors::Engine.routes.url_helpers
        user.roles = [:general_agency_staff]
        sign_in user
        @employer_profile = employer_profile
        render "benefit_sponsors/profiles/employers/broker_agency/active_broker", direct_terminate: true
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
