require 'rails_helper'
require 'csv'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe IvlNotices::FinalEligibilityNoticeRenewalUqhp, :dbclean => :after_each do

  file = "#{Rails.root}/spec/test_data/notices/final_eligibility_notice_uqhp_test_data.csv"
  csv = CSV.open(file,"r",:headers =>true)
  data = csv.to_a
  year = TimeKeeper.date_of_record.year + 1
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :hbx_id => "48574857")}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', csr_variant_id: '01', active_year: 2018, hios_id: "11111111122302-01") }
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual", plan: plan, aasm_state: "auto_renewing", effective_on: Date.new(year,1,1))}
  let!(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let!(:hbx_enrollment_member_1) {FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment_1, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let!(:hbx_enrollment_1) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual", plan: plan, aasm_state: "enrolled_contingent", special_verification_period: TimeKeeper.date_of_record+95.days, effective_on: Date.new(TimeKeeper.date_of_record.year,1,1))}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Final Eligibility Notice for UQHP/AQHP individuals',
      :notice_template => 'notices/ivl/final_eligibility_notice_uqhp_aqhp',
      :notice_builder => 'IvlNotices::FinalEligibilityNoticeRenewalUqhp',
      :event_name => 'final_eligibility_notice_renewal_uqhp',
      :mpi_indicator => 'IVL_FRE',
      :data => data,
      :person =>  person,
      :title => "Your Final Plan Enrollment, And Remainder To Pay"})
  }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :data => data,
      :person => person
  }}

  describe "New" do
    before do
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::FinalEligibilityNoticeRenewalUqhp.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::FinalEligibilityNoticeRenewalUqhp.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "#pick_enrollments" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalUqhp.new(person.consumer_role, valid_parmas)
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      @final_eligibility_notice.append_data
    end

    it "returns all auto_renewing enrollments" do
      @final_eligibility_notice.pick_enrollments
      expect(@final_eligibility_notice.notice.enrollments.size).to eq 1
    end

    it "returns nil when there are no auto_renewing enrollments" do
      hbx_enrollment.update_attributes!(:aasm_state => "coverage_expired")
      @final_eligibility_notice.pick_enrollments
      expect(@final_eligibility_notice.notice.enrollments.size).to eq 0
    end
  end


  describe "#append_data" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalUqhp.new(person.consumer_role, valid_parmas)
      @final_eligibility_notice.append_data
    end

    it "should return coverage year" do
      expect(@final_eligibility_notice.notice.coverage_year).to eq hbx_enrollment.effective_on.year.to_s
    end
    it "should return notification type" do
      expect(@final_eligibility_notice.notice.notification_type).to eq application_event.event_name
    end
    it "should return ivl open enrollment start on" do
      expect(@final_eligibility_notice.notice.ivl_open_enrollment_start_on).to eq Settings.aca.individual_market.open_enrollment.start_on
    end
    it "should return ivl open enrollment end on" do
      expect(@final_eligibility_notice.notice.ivl_open_enrollment_end_on).to eq Settings.aca.individual_market.open_enrollment.end_on
    end
    it "should return person first name" do
      expect(@final_eligibility_notice.notice.primary_firstname).to eq person.first_name
    end
  end

  describe "#generate_pdf_notice" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalUqhp.new(person.consumer_role, valid_parmas)
    end

    it "should render the final eligibility notice template" do
      expect(@final_eligibility_notice.template).to eq "notices/ivl/final_eligibility_notice_uqhp_aqhp"
    end

    it "should generate pdf" do
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      person.primary_family.update_attributes(min_verification_due_date: TimeKeeper.date_of_record + 95.days)
      @final_eligibility_notice.build
      file = @final_eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end
end
