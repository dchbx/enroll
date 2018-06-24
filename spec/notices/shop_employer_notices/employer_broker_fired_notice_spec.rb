require 'rails_helper'

RSpec.describe ShopEmployerNotices::EmployerBrokerFiredNotice do
  before(:all) do
    @employer_profile = FactoryGirl.create(:employer_profile)
    @broker_role =  FactoryGirl.create(:broker_role, aasm_state: 'active')
    @organization = FactoryGirl.create(:broker_agency, legal_name: "agencyone")
    @organization.broker_agency_profile.update_attributes(primary_broker_role: @broker_role)
    @broker_role.update_attributes(broker_agency_profile_id: @organization.broker_agency_profile.id)
    @organization.broker_agency_profile.approve!
    @employer_profile.broker_role_id = @broker_role.id
    @employer_profile.hire_broker_agency(@organization.broker_agency_profile)
    @employer_profile.save!(validate: false)
  end

  let(:organization) { @organization }
  let(:employer_profile){@employer_profile }
  let(:person) { @broker_role.person }
  let(:broker_role) { @broker_role }
  let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: @organization.broker_agency_profile,employer_profile: @employer_profile)}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'draft', :fte_count => 55) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:end_on) {TimeKeeper.date_of_record}

  #add person to broker agency profile
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Broker fired',
      :notice_template => 'notices/shop_employer_notices/employer_broker_fired_notice',
      :notice_builder => 'ShopEmployerNotices::EmployerBrokerFiredNotice',
      :mpi_indicator => 'MPI_SHOP52',
      :event_name => 'employer_broker_fired',
      :title => "Confirmation of Broker Fired to Employer"})
  }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
      before do
        allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
        @employer_notice = ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)
      end
      it "should build notice with all necessary info" do
        @employer_notice.build
        expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
        expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
        expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
      end
  end

  describe "append_data" do
    let(:employer_profile)      { FactoryGirl.create(:employer_profile)}
    let(:broker_agency_profile) { FactoryGirl.build(:broker_agency_profile) }
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)
    end

    it "should append necessary" do
      FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile, employer_profile: employer_profile, is_active: 'true')
      employer_profile.fire_broker_agency
      employer_profile.save
      broker = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile
      broker_role = broker.primary_broker_role
      person = broker_role.person
      @employer_notice.append_data
      expect(@employer_notice.notice.broker.first_name).to eq(person.first_name)
      expect(@employer_notice.notice.broker.last_name).to eq(person.last_name)
      expect(@employer_notice.notice.broker.terminated_on).to eq(employer_profile.broker_agency_accounts.unscoped.last.end_on)
      expect(@employer_notice.notice.broker.organization).to eq (broker.legal_name)
    end
  end

  describe "Rendering notice template and genearte pdf" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @eligibility_notice = ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)
    end
    it "should render notice" do
      expect(@eligibility_notice.template).to eq "notices/shop_employer_notices/employer_broker_fired_notice"
    end
    it "should generate pdf" do
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      file = @eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
