require 'rails_helper'
require 'csv'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe IvlNotices::SecondIvlRenewalNotice, :dbclean => :after_each do

  file = "#{Rails.root}/spec/test_data/notices/second_ivl_renewal_notice_test_data.csv"
  csv = CSV.open(file,"r",:headers =>true)
  data = csv.to_a
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :hbx_id => "383883748")}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual")}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'September Projected Renewal Notice',
                            :notice_template => 'notices/ivl/projected_eligibility_notice',
                            :notice_builder => 'IvlNotices::SecondIvlRenewalNotice',
                            :event_name => 'ivl_renewal_notice_2',
                            :mpi_indicator => 'IVL_PRE',
                            :data => data,
                            :person =>  person,
                            :primary_identifier => data.first["ic_ref"],
                            :title => "2017 Health Insurance Coverage and Preliminary Renewal Information"})
                          }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :data => data,
      :person =>  person,
      :primary_identifier => data.first["ic_ref"]
  }}
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }

  describe "New" do
    before do
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::SecondIvlRenewalNotice.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::SecondIvlRenewalNotice.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "#build" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @proj_eligibility_notice = IvlNotices::SecondIvlRenewalNotice.new(person.consumer_role, valid_parmas)
      @proj_eligibility_notice.build
    end

    it "returns coverage_year" do
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if bcp.start_on.year == TimeKeeper.date_of_record.next_year.year }
      expect(@proj_eligibility_notice.notice.coverage_year).to eq bc_period.start_on.year.to_s
    end

    it "returns event_name" do
      expect(@proj_eligibility_notice.notice.notification_type).to eq application_event.event_name
    end

    it "returns mpi_indicator" do
      expect(@proj_eligibility_notice.notice.mpi_indicator).to eq application_event.mpi_indicator
    end
  end

  describe "#append_open_enrollment_data" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @proj_eligibility_notice = IvlNotices::SecondIvlRenewalNotice.new(person.consumer_role, valid_parmas)
      @proj_eligibility_notice.build
    end
    it "return ivl open enrollment start on" do
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if bcp.start_on.year == TimeKeeper.date_of_record.next_year.year }
      expect(@proj_eligibility_notice.notice.ivl_open_enrollment_start_on).to eq bc_period.open_enrollment_start_on
    end
    it "return ivl open enrollment end on" do
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if bcp.start_on.year == TimeKeeper.date_of_record.next_year.year }
      expect(@proj_eligibility_notice.notice.ivl_open_enrollment_end_on).to eq bc_period.open_enrollment_end_on
    end
  end

  describe "#generate_pdf_notice" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @proj_eligibility_notice = IvlNotices::SecondIvlRenewalNotice.new(person.consumer_role, valid_parmas)
    end

    it "should render the projected eligibility notice template" do
      expect(@proj_eligibility_notice.template).to eq "notices/ivl/projected_eligibility_notice"
    end

    it "should generate pdf" do
      @proj_eligibility_notice.append_hbe
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if bcp.start_on.year == TimeKeeper.date_of_record.next_year.year }
      @proj_eligibility_notice.build
      file = @proj_eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end
end
