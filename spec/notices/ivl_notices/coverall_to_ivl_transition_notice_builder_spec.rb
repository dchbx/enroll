require 'rails_helper'

RSpec.describe IvlNotices::CoverallToIvlTransitionNoticeBuilder, dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person, e_case_id: "family_test#1000")}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, created_at: (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days), household: family.households.first, kind: "individual", aasm_state: "enrolled_contingent")}
  let!(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Coverall to IVL Transition Notice',
      :notice_template => 'notices/ivl/coverall_to_ivl_notice',
      :notice_builder => 'IvlNotices::CoverallToIvlTransitionNoticeBuilder',
      :event_name => 'coverall_to_ivl_transition_notice',
      :mpi_indicator => 'IVL_DCH',
      :title => "YOUR INSURANCE THROUGH COVER ALL DC HAS CHANGED TO DC HEALTH LINK"})
  }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {family: family, result: [person]}
  }}

  describe "New" do
    before do
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::CoverallToIvlTransitionNoticeBuilder.new(person.consumer_role, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{IvlNotices::CoverallToIvlTransitionNoticeBuilder.new(person.consumer_role, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before :each do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @cdc_ivl_notice = IvlNotices::CoverallToIvlTransitionNoticeBuilder.new(person.consumer_role, valid_params)
      @cdc_ivl_notice.build
    end
    it "should return person full name" do
      expect(@cdc_ivl_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
    it "should return person hbx_id" do
      expect(@cdc_ivl_notice.notice.primary_identifier).to eq person.hbx_id
    end
  end


  describe "render template and generate pdf" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @cdc_ivl_notice = IvlNotices::CoverallToIvlTransitionNoticeBuilder.new(person.consumer_role, valid_params)
    end

    it "should render environment_notice" do
      expect(@cdc_ivl_notice.template).to eq "notices/ivl/coverall_to_ivl_notice"
    end

    it "should generate pdf" do
      @cdc_ivl_notice.append_hbe
      @cdc_ivl_notice.build
      file = @cdc_ivl_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end