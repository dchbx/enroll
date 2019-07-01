require 'rails_helper'

RSpec.describe IvlNotices::IvlToCoverallTransitionNoticeBuilder, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person, e_case_id: "family_test#1000")}
  let!(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :family => family,
                      :created_at => (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days),
                      :household => family.households.first,
                      :kind => "individual",
                      :is_any_enrollment_member_outstanding => true)
  end
  let!(:hbx_enrollment_member) {FactoryBot.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Ivl to Coverall Transition Notice',
      :notice_template => 'notices/ivl/ivl_to_coverall_notice',
      :notice_builder => 'IvlNotices::IvlToCoverallTransitionNoticeBuilder',
      :event_name => 'ivl_to_coverall_transition_notice',
      :mpi_indicator => 'IVL_CDC',
      :title => "Your Insurance through DC Health Link Has Changed to Cover All DC"})
  }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {family: family.id.to_s, result: {people: [person.id.to_s]}}
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

  describe "#notice_filename" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @ivl_cdc_notice = IvlNotices::IvlToCoverallTransitionNoticeBuilder.new(person.consumer_role, valid_params)
    end

    it "should have caps DC in the title" do
      title = @ivl_cdc_notice.notice_filename
      expect(title).to match (/DC/)
    end

    it "should not have Dc in the title" do
      title = @ivl_cdc_notice.notice_filename
      expect(title).not_to match (/Dc/)
    end

    it "should not have Dc in the title" do
      title = @ivl_cdc_notice.notice_filename
      expect(title).to match (/YourInsuranceThroughDCHealthLinkHasChangedToCoverAllDC/)
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