require 'rails_helper'

RSpec.describe IvlNotices::IvlToCoverallTransitionNoticeBuilder, dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person, e_case_id: "family_test#1000")}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, created_at: (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days), household: family.households.first, kind: "individual", aasm_state: "enrolled_contingent")}
  let!(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Ivl to Coverall Transition Notice',
      :notice_template => 'notices/ivl/ivl_to_coverall_notice',
      :notice_builder => 'IvlNotices::IvlToCoverallTransitionNoticeBuilder',
      :event_name => 'ivl_to_coverall_transition_notice',
      :mpi_indicator => 'IVL_CDC',
      :title => "YOUR INSURANCE THROUGH DC HEALTH LINK HAS CHANGED TO COVER ALL DC"})
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
        expect{IvlNotices::IvlToCoverallTransitionNoticeBuilder.new(person.consumer_role, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{IvlNotices::IvlToCoverallTransitionNoticeBuilder.new(person.consumer_role, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before :each do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @ivl_cdc_notice = IvlNotices::IvlToCoverallTransitionNoticeBuilder.new(person.consumer_role, valid_params)
      @ivl_cdc_notice.build
    end
    it "should return person full name" do
      expect(@ivl_cdc_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
    it "should return person hbx_id" do
      expect(@ivl_cdc_notice.notice.primary_identifier).to eq person.hbx_id
    end

    it "should return past due text" do
      expect(@ivl_cdc_notice.notice.past_due_text).to eq "PAST DUE"
    end
  end

  describe "#attach_required_documents" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @ivl_cdc_notice = IvlNotices::IvlToCoverallTransitionNoticeBuilder.new(person.consumer_role, valid_params)
    end

    it "should render documents section" do
      @ivl_cdc_notice.append_hbe
      @ivl_cdc_notice.build
      expect(@ivl_cdc_notice).to receive :attach_required_documents
      @ivl_cdc_notice.attach_docs
    end
  end

  describe "render template and generate pdf" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @ivl_cdc_notice = IvlNotices::IvlToCoverallTransitionNoticeBuilder.new(person.consumer_role, valid_params)
    end

    it "should render environment_notice" do
      expect(@ivl_cdc_notice.template).to eq "notices/ivl/ivl_to_coverall_notice"
    end

    it "should generate pdf" do
      @ivl_cdc_notice.append_hbe
      @ivl_cdc_notice.build
      file = @ivl_cdc_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end