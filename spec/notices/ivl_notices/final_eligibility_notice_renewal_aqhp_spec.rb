require 'rails_helper'
require 'csv'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe IvlNotices::FinalEligibilityNoticeRenewalAqhp, :dbclean => :after_each do

  file = "#{Rails.root}/spec/test_data/notices/final_eligibility_notice_aqhp_test_data.csv"
  csv = CSV.open(file,"r",:headers =>true)
  data = csv.to_a
  year = TimeKeeper.date_of_record.year + 1
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :hbx_id => "383883742")}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', csr_variant_id: '01', active_year: year, hios_id: "11111111122302-01") }
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual", plan: plan, aasm_state: "auto_renewing", effective_on: Date.new(year,1,1))}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Final Eligibility Notice for UQHP/AQHP individuals',
      :notice_template => 'notices/ivl/final_eligibility_notice_uqhp_aqhp',
      :notice_builder => 'IvlNotices::FinalEligibilityNoticeRenewalAqhp',
      :event_name => 'final_eligibility_notice_renewal_aqhp',
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
      enrollments: [hbx_enrollment],
      :person => person
  }}

  describe "New" do
    before do
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "#build" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_parmas)
      @final_eligibility_notice.build
    end

    it "returns coverage_year" do
      expect(@final_eligibility_notice.notice.coverage_year).to eq hbx_enrollment.effective_on.year.to_s
    end

    it "returns event_name" do
      expect(@final_eligibility_notice.notice.notification_type).to eq application_event.event_name
    end

    it "returns mpi_indicator" do
      expect(@final_eligibility_notice.notice.mpi_indicator).to eq application_event.mpi_indicator
    end
  end

  describe "#append_open_enrollment_data" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_parmas)
      @final_eligibility_notice.build
    end
    it "return ivl open enrollment start on" do
      expect(@final_eligibility_notice.notice.ivl_open_enrollment_start_on).to eq Settings.aca.individual_market.open_enrollment.start_on
    end
    it "return ivl open enrollment end on" do
      expect(@final_eligibility_notice.notice.ivl_open_enrollment_end_on).to eq Settings.aca.individual_market.open_enrollment.end_on
    end
  end

  describe "#generate_pdf_notice" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_parmas)
    end

    it "should render the final eligibility notice template" do
      expect(@final_eligibility_notice.template).to eq "notices/ivl/final_eligibility_notice_uqhp_aqhp"
    end

    it "should generate pdf" do
      @final_eligibility_notice.append_hbe
      @final_eligibility_notice.build
      file = @final_eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end
end
