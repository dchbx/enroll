require 'rails_helper'

if ExchangeTestingConfigurationHelper.general_agency_enabled?
RSpec.describe ShopGeneralAgencyNotices::GeneralAgencyHiredNotice, :dbclean => :after_each do
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, organization: organization) }
  let!(:person) { FactoryGirl.create(:person, :with_work_email, :with_hbx_staff_role) }
  let!(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let!(:general_agency_staff_role) {FactoryGirl.create(:general_agency_staff_role, general_agency_profile: general_agency_profile, person: person)}
  let!(:organization) {FactoryGirl.create(:organization)}
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, general_agency_profile: general_agency_profile) }
  let!(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization ) }
  let!(:broker_role) {  broker_agency_profile.primary_broker_role }
  let!(:application_event){ double("ApplicationEventKind",{
                            :name =>'General Agency hired notification',
                            :notice_template => 'notices/shop_general_agency_notices/general_agency_hired_notice',
                            :notice_builder => 'ShopGeneralAgencyNotices::GeneralAgencyHiredNotice',
                            :mpi_indicator => 'SHOP_D085',
                            :event_name => 'general_agency_hired_notice',
                            :title => "Employer has hired you as a General agency"})
                          }
  let!(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {
        :employer_profile_id => employer_profile.id.to_s
      }
  }}

  before do
    @general_agency_notice = ShopGeneralAgencyNotices::GeneralAgencyHiredNotice.new(general_agency_profile, valid_params)
    allow(general_agency_profile).to receive(:general_agency_staff_roles).and_return([general_agency_staff_role])
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{ShopGeneralAgencyNotices::GeneralAgencyHiredNotice.new(general_agency_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopGeneralAgencyNotices::GeneralAgencyHiredNotice.new(general_agency_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    it "should build notice with all necessory info" do
      @general_agency_notice.build
      expect(@general_agency_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
  end

  describe "append data" do
    before :each do
      person.employer_staff_roles.create!(employer_profile_id: employer_profile.id)
      employer_profile.broker_agency_accounts.create!(broker_agency_profile_id: broker_agency_profile.id, start_on: TimeKeeper.date_of_record - 35.days)
    end

    it "should append employer staff name" do
      @general_agency_notice.append_data
      expect(@general_agency_notice.notice.general_agency.employer_fullname).to eq employer_profile.staff_roles.first.full_name.titleize
    end

    it "should append employer legal name" do
      @general_agency_notice.append_data
      expect(@general_agency_notice.notice.general_agency.employer).to eq employer_profile.organization.legal_name
    end

    it "should append broker_fullname" do
      @general_agency_notice.append_data
      expect(@general_agency_notice.notice.general_agency.broker_fullname).to eq broker_role.person.full_name
    end

    describe "for generating pdf" do
      it "should generate pdf" do
        @general_agency_notice.build
        @general_agency_notice.append_data
        file = @general_agency_notice.generate_pdf_notice
        expect(File.exist?(file.path)).to be true
      end
    end
  end

  describe "should render template" do
    it "render broker_fires_default_ga_notice" do
      expect(@general_agency_notice.template).to eq "notices/shop_general_agency_notices/general_agency_hired_notice"
    end
  end
end
end
