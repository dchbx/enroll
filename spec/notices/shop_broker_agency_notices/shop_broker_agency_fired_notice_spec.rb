require 'rails_helper'

RSpec.describe ShopBrokerAgencyNotices::BrokerAgencyFiredNotice do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile}
  let!(:broker_agency_profile) { create :broker_agency_profile }
  let!(:broker_agency_account) { create :broker_agency_account }
  let!(:person){ create :person }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Broker Agency Fired',
                            :notice_template => 'notices/shop_broker_agency_notices/broker_agency_fired_notice',
                            :notice_builder => 'ShopBrokerAgencyNotices::BrokerAgencyFiredNotice',
                            :event_name => 'broker_agency_fired_confirmation',
                            :mpi_indicator => 'SHOP_M047',
                            :title => "You have been removed as a Broker"})
                          }
    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}
    describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
      allow(employer_profile).to receive_message_chain("broker_agency_accounts.unscoped.last.broker_agency_profile").and_return(broker_agency_profile)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopBrokerAgencyNotices::BrokerAgencyFiredNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopBrokerAgencyNotices::BrokerAgencyFiredNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
      allow(employer_profile).to receive_message_chain("broker_agency_accounts.detect").and_return(broker_agency_account)
      allow(employer_profile).to receive_message_chain("broker_agency_accounts.unscoped.last.broker_agency_profile").and_return(broker_agency_profile)
      @broker_agency_profile_notice = ShopBrokerAgencyNotices::BrokerAgencyFiredNotice.new(employer_profile, valid_parmas)

    end
    it "should build notice with all necessory info" do
      @broker_agency_profile_notice.build
      expect(@broker_agency_profile_notice.notice.employer_name).to eq employer_profile.legal_name.titleize
      expect(@broker_agency_profile_notice.notice.employer_first_name).to eq employer_profile.staff_roles.first.first_name
      expect(@broker_agency_profile_notice.notice.employer_last_name).to eq employer_profile.staff_roles.first.last_name
      expect(@broker_agency_profile_notice.notice.email).to eq employer_profile.staff_roles.first.work_email_or_best
      expect(@broker_agency_profile_notice.notice.phone).to eq broker_agency_profile.phone
    end
  end
end