require 'rails_helper'

RSpec.describe IvlNotices::EligibilityNoticeBuilder do
	let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual")}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Eligibility Notice',
                            :notice_template => 'notices/ivl/eligibility_notice',
                            :notice_builder => 'IvlNotices::EligibilityNoticeBuilder',
                            :event_name => 'eligibility_notice',
                            :mpi_indicator => 'IVL_ELA',
                            :title => "Eligibility notice"})
                          }
    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }

    describe "New" do
    before do
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::EligibilityNoticeBuilder.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::EligibilityNoticeBuilder.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end


  describe "Build" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EligibilityNoticeBuilder.new(person.consumer_role, valid_parmas)
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    end

    it "should build notice with all necessory info start_on" do
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
      person.primary_family.applications.create!(:aasm_state => 'eligible')
      @eligibility_notice.build
      expect(@eligibility_notice.notice.ivl_open_enrollment_start_on).to eq bc_period.open_enrollment_start_on
    end

     it "should build notice with all necessory info end_on" do
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
      person.primary_family.applications.create!(:aasm_state => 'eligible')
      @eligibility_notice.build
      expect(@eligibility_notice.notice.ivl_open_enrollment_end_on).to eq bc_period.open_enrollment_end_on
    end
  end

  describe "Rendering environment_notice template" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EligibilityNoticeBuilder.new(person.consumer_role, valid_parmas)
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    end

    it "should render environment_notice" do
      expect(@eligibility_notice.template).to eq "notices/ivl/eligibility_notice"
    end
  end
end