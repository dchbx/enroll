require 'rails_helper'

RSpec.describe ShopBrokerNotices::BrokerFiredNotice do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile}
  let!(:broker_agency_profile) { create :broker_agency_profile }
  let(:broker_agency_staff_role) {FactoryGirl.create(:broker_agency_staff_role, broker_agency_profile: broker_agency_profile)}
  let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
  let!(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile,employer_profile: employer_profile, end_on: TimeKeeper.date_of_record)}
  let!(:person){ create :person }
  let!(:broker_person) { broker_agency_staff_role.person }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Broker Fired',
                            :notice_template => 'notices/shop_broker_notices/broker_fired_notice',
                            :notice_builder => 'ShopBrokerNotices::BrokerFiredNotice',
                            :event_name => 'broker_fired_confirmation_to_broker',
                            :mpi_indicator => 'SHOP_D051)',
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
      allow(employer_profile).to receive_message_chain("broker_agency_accounts.unscoped.last").and_return(broker_agency_account)
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopBrokerNotices::BrokerFiredNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopBrokerNotices::BrokerFiredNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      allow(employer_profile).to receive_message_chain("broker_agency_accounts.unscoped.last").and_return(broker_agency_account)
      @broker_notice = ShopBrokerNotices::BrokerFiredNotice.new(employer_profile, valid_parmas)
      @broker_notice.build
    end
    it "should return broker_agency legal name" do
      expect(@broker_notice.notice.broker_agency).to eq broker_agency_profile.legal_name.titleize
    end
    it "should return assignment end date" do
      expect(@broker_notice.notice.termination_date).to eq broker_agency_account.end_on
    end
  end

  describe "Render template & Generate PDF" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      allow(employer_profile).to receive_message_chain("broker_agency_accounts.unscoped.last").and_return(broker_agency_account)
      @broker_notice = ShopBrokerNotices::BrokerFiredNotice.new(employer_profile, valid_parmas)
    end
    it "should render broker_fired_notice" do
      expect(@broker_notice.template).to eq "notices/shop_broker_notices/broker_fired_notice"
    end
    it "should generate pdf" do
      @broker_notice.build
      @broker_notice.generate_pdf_notice
      file = @broker_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
