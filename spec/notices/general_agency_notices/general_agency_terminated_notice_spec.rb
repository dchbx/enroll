require 'rails_helper'

RSpec.describe GeneralAgencyNotices::GeneralAgencyTerminatedNotice, dbclean: :after_each do
	let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ FactoryGirl.create :employer_profile}
  let!(:general_agency_profile) { FactoryGirl.create :general_agency_profile }
  let!(:general_agency_account) { FactoryGirl.create :general_agency_account ,aasm_state: 'inactive',employer_profile: employer_profile, general_agency_profile_id: general_agency_profile.id, end_on: TimeKeeper.date_of_record}
  let!(:general_agency_staff_role) { FactoryGirl.create(:general_agency_staff_role, general_agency_profile_id: general_agency_profile.id, :aasm_state => 'active')}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }  
  let(:application_event){ double("ApplicationEventKind",{
                             :name =>'GA Fired',
                             :notice_template => 'notices/general_agency_notices/general_agency_fired_notice',
                             :notice_builder => 'GeneralAgencyNotices::GeneralAgencyTerminatedNotice',
                             :event_name => 'general_agency_terminated',
                             :mpi_indicator => 'SHOP_D086',
                             :title => "Genaral Agency Fired"})
                          }
    let(:valid_parmas) {{
     :subject => application_event.title,
     :mpi_indicator => application_event.mpi_indicator,
     :event_name => application_event.event_name,
     :template => application_event.notice_template
  }}

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{GeneralAgencyNotices::GeneralAgencyTerminatedNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{GeneralAgencyNotices::GeneralAgencyTerminatedNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @general_agency_notice = GeneralAgencyNotices::GeneralAgencyTerminatedNotice.new(employer_profile, valid_parmas)
      @general_agency_notice.build
    end

    it "should return general agency legal name" do
      expect(@general_agency_notice.notice.primary_fullname).to eq general_agency_profile.legal_name
    end

    it "should return email" do
      expect(@general_agency_notice.notice.ga_email).to eq general_agency_staff_role.person.work_email_or_best
    end

    it "should return employer name" do
      expect(@general_agency_notice.notice.employer_name).to eq employer_profile.legal_name
    end

    it "should return employer name" do
      expect(@general_agency_notice.notice.terminated_on).to eq general_agency_account.end_on
    end
  end

  describe "Render template & Generate PDF" do
    before do
      @general_agency_notice = GeneralAgencyNotices::GeneralAgencyTerminatedNotice.new(employer_profile, valid_parmas)
      @general_agency_notice.build
    end

    it "should render general_agency_fired_notice" do
      expect(@general_agency_notice.template).to eq "notices/general_agency_notices/general_agency_fired_notice"
    end

    it "should generate pdf" do
      file = @general_agency_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
