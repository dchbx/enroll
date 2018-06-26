require 'rails_helper'

RSpec.describe ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop, :dbclean => :after_each do
  let(:plan) { FactoryGirl.create(:plan) }
  let(:plan2) { FactoryGirl.create(:plan) }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'terminated', terminated_on: TimeKeeper.date_of_record.beginning_of_year ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let(:application_event){ double("ApplicationEventKind",{
      :name =>"Notice to EEs when  ER’s equest termination in advance",
      :notice_template => 'notices/shop_employee_notices/notice_to_employees_that_active_er_is_terminated_from_shop',
      :notice_builder => 'ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop',
      :event_name => 'notify_employee_of_group_advance_termination',
      :mpi_indicator => 'SHOP_D044',
      :title => "Termination of Employer’s Health Coverage Offered Through The DC Health Link"})
  }


  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop.new(census_employee, valid_params)
    end
    it "should build notice with all necessory info" do

      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append_data" do
    before do
      @employee_notice = ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop.new(census_employee, valid_params)
    end
    it "should append data" do
      @employee_notice.append_data
      expect(@employee_notice.notice.plan_year.terminated_on).to eq plan_year.terminated_on
    end
  end

  describe "Rendering intitial shop application approval notice template and generate pdf" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop.new(census_employee, valid_params)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
    end
    it "should render termination_of_employers_health_coverage" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/notice_to_employees_that_active_er_is_terminated_from_shop"
    end

    it "should generate pdf" do
      @employee_notice.build
      @employee_notice.append_data
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end