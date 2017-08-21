require 'rails_helper'

RSpec.describe IvlNotices::EnrollmentNoticeBuilder do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual")}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Enrollment Notice',
                            :notice_template => 'notices/ivl/enrollment_notice',
                            :notice_builder => 'IvlNotices::EnrollmentNoticeBuilder',
                            :event_name => 'enrollment_notice',
                            :mpi_indicator => 'IVL_ENR',
                            :title => "Enrollment notice"})
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
        expect{IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person.consumer_role).to receive_message_chain("person.families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_parmas)
    end
    it "should build notice with all necessory info" do
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
      @eligibility_notice.build
      expect(@eligibility_notice.notice.coverage_year).to eq bc_period.start_on.year.to_s
      expect(@eligibility_notice.notice.enrollments.first.coverage_kind).to eq hbx_enrollment.coverage_kind
      expect(@eligibility_notice.notice.enrollments.first.plan.plan_name).to eq hbx_enrollment.plan.name
      expect(@eligibility_notice.notice.enrollments.first.plan.plan_carrier).to eq hbx_enrollment.plan.carrier_profile.organization.legal_name
      expect(@eligibility_notice.notice.enrollments.first.plan.deductible).to eq hbx_enrollment.plan.deductible
      expect(@eligibility_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@eligibility_notice.notice.primary_identifier).to eq person.hbx_id
    end
  end

end