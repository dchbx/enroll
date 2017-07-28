require 'rails_helper'

RSpec.describe ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice do
  let(:address)  { Address.new(kind: "primary", address_1: "3234 R st", city: "Alexandria", state: "VA", zip: "20402") }
  let(:office_location) do
    OfficeLocation.new(
      is_primary: true,
      address: address
      )
  end
  let(:organization) { Organization.create(
    legal_name: "Sail Adventures, Inc",
    dba: "Sail Away",
    fein: "001223333",
    office_locations: [office_location]
    )
  }
  let(:employer_profile) { FactoryGirl.create :employer_profile, organization: organization}
  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:person){ create :person}
  let!(:active_plan_year) { FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :active, :start_on => Date.new(calender_year - 1, 5, 1), :end_on => Date.new(calender_year, 4, 30)}
  let!(:renewing_plan_year) { FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_publish_pending, :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30)}
  let(:warnings) { { primary_office_location: "primary location is outside washington dc"} }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Employer Annual Renewal - Denial of Eligibility',
                            :notice_template => 'notices/shop_employer_notices/employer_renewal_eligibility_denial_notice',
                            :notice_builder => 'ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice',
                            :event_name => 'employer_renewal_eligibility_denial_notice',
                            :mpi_indicator => 'MPI_SHOP33',
                            :title => "Employer Annual Renewal - Denial of Eligibility"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :organization => organization
  }}

  describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(employer_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(employer_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(employer_profile, valid_params)
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
      @employer_notice = ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(employer_profile, valid_params)
      allow(renewing_plan_year).to receive(:application_eligibility_warnings).and_return(warnings)
      allow(renewing_plan_year).to receive(:is_application_valid?).and_return(false)
    end

    it "should append necessary" do
      renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_publish_pending").first
      active_plan_year = employer_profile.plan_years.where(:aasm_state => "active").first
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq renewing_plan_year.start_on
      expect(@employer_notice.notice.plan_year.end_on).to eq active_plan_year.end_on
      expect(@employer_notice.notice.plan_year.warnings).to eq ["primary location is outside washington dc"]
    end
  end

end