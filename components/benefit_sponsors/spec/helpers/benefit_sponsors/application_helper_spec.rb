require 'rails_helper'

RSpec.describe BenefitSponsors::ApplicationHelper, type: :helper, dbclean: :after_each do
  include BenefitSponsors::ApplicationHelper

  describe '.profile_unread_messages_count', dbclean: :after_each do
    let(:inbox) { double('inbox', unread_messages: [1], unread_messages_count: 2 )}
    let(:profile) { double('Profile', inbox: inbox)}

    context 'when profile is an instance of BenefitSponsors::Organizations::Profile then' do
      before do
        expect(profile).to receive(:is_a?).and_return(true)
      end
      it { expect(profile_unread_messages_count(profile)).to eq(1) }
    end

    context 'when profile is not an instance of BenefitSponsors::Organizations::Profile then' do
      before do
        expect(profile).to receive(:is_a?).and_return(false)
      end
      it { expect(profile_unread_messages_count(profile)).to eq(2) }
    end

    context 'when there is an error then', dbclean: :after_each do
      let(:site) { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
      let(:broker_organization) { FactoryBot.build(:benefit_sponsors_organizations_general_organization, site: site) }
      let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, organization: broker_organization, market_kind: 'shop', legal_name: 'Legal Name1') }

      it "has the correct number of unread messages" do
        expect(profile_unread_messages_count(broker_agency_profile)).to eq(0)
      end
    end
  end

  describe "add_plan_year_button_business_rule", dbclean: :after_each do
    let!(:rating_area)                   { FactoryBot.create :benefit_markets_locations_rating_area }
    let!(:service_area)                  { FactoryBot.create :benefit_markets_locations_service_area }
    let!(:site)                          { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile)              { organization.employer_profile }
    let!(:active_benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

    let!(:effective_period)              { (TimeKeeper.date_of_record.beginning_of_month)..(TimeKeeper.date_of_record.beginning_of_month.next_year.prev_day) }
    let!(:new_effective_period)          { (TimeKeeper.date_of_record.beginning_of_month.next_year)..(TimeKeeper.date_of_record.beginning_of_month.prev_day + 2.years) }
    let!(:predecessor_application)       { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :active, effective_period: effective_period, benefit_sponsorship: active_benefit_sponsorship) }
    let!(:renewal_application)           { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :active, effective_period: new_effective_period, benefit_sponsorship: active_benefit_sponsorship) }

    context 'should return false when an active PY no canceled PY' do
      it{ expect(add_plan_year_button_business_rule(employer_profile.benefit_applications)).to eq false }
    end

    context 'should return false when a published PY' do
      before do
        renewal_application.update_attributes(:aasm_state => :enrollment_open)
      end
      it {expect(add_plan_year_button_business_rule(employer_profile.benefit_applications)).to eq false}
    end

    context 'should return true when with an active initial and canceled renewal PY with renewal start date is greater the initial end on' do
      before do
        renewal_application.update_attributes(:aasm_state => :canceled)
      end
      it {expect(add_plan_year_button_business_rule(employer_profile.benefit_applications)).to eq true}
    end

    context 'should return false when with an active initial and termination pending renewal PY' do
      before do
        renewal_application.update_attributes(:aasm_state => :termination_pending)
      end
      it {expect(add_plan_year_button_business_rule(employer_profile.benefit_applications)).to eq false}
    end

    context 'should return false when with a published initial and termination pending renewal PY' do
      before do
        predecessor_application.update_attributes(:aasm_state => :enrollment_open)
        renewal_application.update_attributes(:aasm_state => :termination_pending)
      end
      it {expect(add_plan_year_button_business_rule(employer_profile.benefit_applications)).to eq false}
    end

    context 'should return true when with an inactive initial and termination pending renewal PY' do
      before do
        predecessor_application.update_attributes(:aasm_state => :expired)
        renewal_application.update_attributes(:aasm_state => :enrollment_ineligible, effective_period: (TimeKeeper.date_of_record.beginning_of_month)..(TimeKeeper.date_of_record.beginning_of_month.next_year.prev_day))
      end
      it {expect(add_plan_year_button_business_rule(employer_profile.benefit_applications)).to eq true}
    end

    context 'should return false when BA is_renewal true' do
      before do
        renewal_application.update_attributes(:aasm_state => :canceled)
        predecessor_application.update_attributes(:aasm_state => :enrollment_ineligible)
      end
      it {expect(add_plan_year_button_business_rule(employer_profile.benefit_applications)).to eq true}
    end
  end
end
