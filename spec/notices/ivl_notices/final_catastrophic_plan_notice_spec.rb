require 'rails_helper'

RSpec.describe IvlNotices::FinalCatastrophicPlanNotice, dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_mailing_address)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Final Catastrophic Plan Notice',
                            :notice_template => 'notices/ivl/final_catastrophic_plan_letter',
                            :notice_builder => 'IvlNotices::FinalCatastrophicPlanNotice',
                            :event_name => 'final_catastrophic_plan',
                            :mpi_indicator => 'IVL_CAP',
                            :title => "Important Tax Information about your Catastrophic Health Coverage"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::FinalCatastrophicPlanNotice.new(person.consumer_role, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{IvlNotices::FinalCatastrophicPlanNotice.new(person.consumer_role, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "deliver" do
    before :each do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @catastrophic_plan_notice = IvlNotices::FinalCatastrophicPlanNotice.new(person.consumer_role, valid_params)
      @catastrophic_plan_notice.build
    end

    it "should create a pdf template for address" do
      expect(@catastrophic_plan_notice.notice.primary_address.present?).to be_truthy
    end

    it "should receive a primary_fullname" do
      expect(@catastrophic_plan_notice.notice.primary_fullname).to eq person.full_name
    end

    it "should receive attach_taglines" do
      expect(@catastrophic_plan_notice).to receive :attach_taglines
      @catastrophic_plan_notice.attach_taglines
    end

    it "should receive attach_non_discrimination" do
      expect(@catastrophic_plan_notice).to receive :attach_non_discrimination
      @catastrophic_plan_notice.attach_non_discrimination
    end

    it "should receive attach_blank_page" do
      notice_path = @catastrophic_plan_notice.notice_path
      expect(@catastrophic_plan_notice).to receive :attach_blank_page
      @catastrophic_plan_notice.attach_blank_page(notice_path)
    end

    it "should receive send_generic_notice_alert" do
      expect(@catastrophic_plan_notice).to receive :send_generic_notice_alert
      @catastrophic_plan_notice.send_generic_notice_alert
    end

    it "should receive store_paper_notice" do
      expect(@catastrophic_plan_notice).to receive :store_paper_notice
      @catastrophic_plan_notice.store_paper_notice
    end

    it "should have an mpi_indicator" do
      expect(@catastrophic_plan_notice.mpi_indicator).to eq application_event.mpi_indicator
    end
  end

  describe "render template and generate pdf" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @catastrophic_plan_notice = IvlNotices::FinalCatastrophicPlanNotice.new(person.consumer_role, valid_params)
    end

    it "should render final_catastrophic_plan_letter" do
      expect(@catastrophic_plan_notice.template).to eq "notices/ivl/final_catastrophic_plan_letter"
    end

    it "should generate pdf" do
      @catastrophic_plan_notice.append_hbe
      @catastrophic_plan_notice.build
      file = @catastrophic_plan_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end