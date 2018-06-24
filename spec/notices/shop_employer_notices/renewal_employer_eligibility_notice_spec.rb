require 'rails_helper'

RSpec.describe ShopEmployerNotices::RenewalEmployerEligibilityNotice do
  let!(:employer_profile){ create :employer_profile}
  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:calender_month) { (TimeKeeper.date_of_record + 2.months).month}
  let(:start_on) { Date.new(calender_year, calender_month, 1)}
  let(:end_on) { start_on.next_year.prev_day }
  let(:open_enrollment_start_on) { start_on.prev_month }
  let(:open_enrollment_end_on) { open_enrollment_start_on + 10.days}
  let!(:active_plan_year) { FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: "renewing_enrolling", start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on}
  let(:person){ create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'PlanYear Renewal',
                            :notice_template => 'notices/shop_employer_notices/3a_employer_plan_year_renewal',
                            :notice_builder => 'ShopEmployerNotices::RenewalEmployerEligibilityNotice',
                            :mpi_indicator => 'MPI_SHOPRA',
                            :event_name => 'planyear_renewal_3a',
                            :title => "Plan Offerings Finalized"})
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
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::RenewalEmployerEligibilityNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::RenewalEmployerEligibilityNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::RenewalEmployerEligibilityNotice.new(employer_profile, valid_parmas)
    end
    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
      expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

  describe "Build_plan_year" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::RenewalEmployerEligibilityNotice.new(employer_profile, valid_parmas)
      @employer_notice.build_plan_year
    end

    it "should append open enrollment start on info" do  
      expect(@employer_notice.notice.plan_year.open_enrollment_start_on).to eq active_plan_year.open_enrollment_start_on
    end
    it "should append open enrollment end on info" do 
      expect(@employer_notice.notice.plan_year.open_enrollment_end_on).to eq active_plan_year.open_enrollment_end_on
    end
  end 

  describe "Rendering employer_eligibility_notice template" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::RenewalEmployerEligibilityNotice.new(employer_profile, valid_parmas)
    end

    it "should render employer_eligibility_notice" do
      expect(@employer_notice.template).to eq "notices/shop_employer_notices/3a_employer_plan_year_renewal"
    end

    it "should generate pdf" do
      @employer_notice.build
      @employer_notice.build_plan_year
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
   
end
