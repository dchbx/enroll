require 'rails_helper'

RSpec.describe ShopEmployerNotices::RenewalEmployerIneligibilityNotice do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_enrolling') }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal Group Ineligible to Obtain Coverage',
                            :notice_template => 'notices/shop_employer_notices/19_renewal_employer_ineligibility_notice',
                            :notice_builder => 'ShopEmployerNotices::RenewalEmployerIneligibilityNotice',
                            :event_name => 'renewal_employer_ineligibility_notice',
                            :mpi_indicator => 'SHOP_D019',
                            :title => "Group Ineligible to Obtain Coverage"})
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
        expect{ShopEmployerNotices::RenewalEmployerIneligibilityNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::RenewalEmployerIneligibilityNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::RenewalEmployerIneligibilityNotice.new(employer_profile, valid_parmas)
    end
    it "should build notice with all necessary info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
      expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

  describe "append_data" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      TimeKeeper.set_date_of_record_unprotected!(renewal_plan_year.open_enrollment_end_on.next_day)
      renewal_plan_year.advance_date!
      @employer_notice = ShopEmployerNotices::RenewalEmployerIneligibilityNotice.new(employer_profile, valid_parmas)
      @employer_notice.append_data
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    it "should return renewal plan year start on" do
      expect(@employer_notice.notice.plan_year.start_on).to eq renewal_plan_year.start_on
    end

    it "should return open enrollment end on date" do
      expect(@employer_notice.notice.plan_year.open_enrollment_end_on).to eq renewal_plan_year.open_enrollment_end_on
    end

    it "should return active plan year end on" do
      expect(@employer_notice.notice.plan_year.end_on).to eq plan_year.end_on
    end

    it "should return plan year warnings" do
      if renewal_plan_year.start_on.yday != 1
        expect(@employer_notice.notice.plan_year.warnings).to eq ["At least two-thirds of your eligible employees enrolled in your group health coverage or waive due to having other coverage."]
      else
        expect(@employer_notice.notice.plan_year.warnings).to eq []
      end
    end
  end

end
