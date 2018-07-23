require 'rails_helper'
require 'csv'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe IvlNotices::IvlBacklogVerificationNoticeUqhp, :dbclean => :after_each do

  file = "#{Rails.root}/spec/test_data/notices/ivl_backlog_notice.csv"
  csv = CSV.open(file,"r",:headers =>true)
  data = csv.to_a
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :hbx_id => "39587345")}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, min_verification_due_date: TimeKeeper.date_of_record, person: person)}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Backlog Notice',
      :notice_template => 'notices/ivl/ivl_backlog_verification_notice_uqhp',
      :notice_builder => 'IvlNotices::IvlBacklogVerificationNoticeUqhp',
      :event_name => 'ivl_backlog_verification_notice_uqhp',
      :mpi_indicator => 'IVL_BV',
      :title => "You Must Submit Documents by the Deadline to Keep Your Insurance"})
  }
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :person => person,
      :family => family,
      :data => data
  }}


  describe "New" do
    before do
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::IvlBacklogVerificationNoticeUqhp.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::IvlBacklogVerificationNoticeUqhp.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "#build" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @ivl_backlog_notice = IvlNotices::IvlBacklogVerificationNoticeUqhp.new(person.consumer_role, valid_parmas)
      @ivl_backlog_notice.build
    end

    it "returns person's first_name" do
      expect(@ivl_backlog_notice.notice.primary_firstname).to eq person.first_name
    end

    it "returns event_name" do
      expect(@ivl_backlog_notice.notice.notification_type).to eq application_event.event_name
    end

    it "returns mpi_indicator" do
      expect(@ivl_backlog_notice.notice.mpi_indicator).to eq application_event.mpi_indicator
    end
  end

  describe "#generate_pdf_notice" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @backlog_notice = IvlNotices::IvlBacklogVerificationNoticeUqhp.new(person.consumer_role, valid_parmas)
    end

    it "should render the final eligibility notice template" do
      expect(@backlog_notice.template).to eq "notices/ivl/ivl_backlog_verification_notice_uqhp"
    end

    it "should generate pdf" do
      @backlog_notice.append_hbe
      @backlog_notice.build
      file = @backlog_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end
end
