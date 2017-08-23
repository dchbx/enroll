require 'rails_helper'

RSpec.describe ShopEmployeeNotices::CongressEmployeeDependentAgeOffTerminationNotice, :dbclean => :after_each do
  let(:hbx_profile) {double}
  let(:benefit_sponsorship) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, renewal_benefit_coverage_period: renewal_bcp, current_benefit_coverage_period: bcp) }
  let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, start_on: TimeKeeper.date_of_record.beginning_of_year, end_on: TimeKeeper.date_of_record.end_of_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.next_year.year,11,1), open_enrollment_end_on: Date.new((TimeKeeper.date_of_record+2.years).year,1,31)) }
  let(:renewal_bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, start_on: TimeKeeper.date_of_record.beginning_of_year.next_year, end_on: TimeKeeper.date_of_record.end_of_year.next_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.year,11,1), open_enrollment_end_on: Date.new(TimeKeeper.date_of_record.next_year.year,1,31)) }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'application_ineligible' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group_id: active_benefit_group.id, census_employee: census_employee, start_on: start_on) }
  let(:date) {TimeKeeper.date_of_record}
  let(:family) {
      family = FactoryGirl.build(:family, :with_primary_family_member_and_dependent)
      primary_person = family.family_members.where(is_primary_applicant: true).first.person
      other_child_person1 = family.family_members.where(is_primary_applicant: false).first.person
      other_child_person2 = family.family_members.where(is_primary_applicant: false).last.person
      primary_person.person_relationships << PersonRelationship.new(relative_id: other_child_person1.id, kind: "child")
      primary_person.person_relationships << PersonRelationship.new(relative_id: other_child_person2.id, kind: "child")
      primary_person.save
      other_child_person1.dob = Date.new(date.year,date.month,date.beginning_of_month.day) - 26.years
      other_child_person2.dob = Date.new(date.year,date.month,date.beginning_of_month.day) - 26.years
      family.save
      family
    }

  let(:enrollment) do
    hbx = FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "individual")
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).first.id, is_subscriber: false)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).last.id, is_subscriber: false)
    hbx.save
    hbx
  end

  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Notice to EE of DPT Termination due to Age-Off (Congressional)',
                            :notice_template => 'notices/shop_employee_notices/congress_employee_dependent_age_off_termination_notice',
                            :notice_builder => 'ShopEmployeeNotices::CongressEmployeeDependentAgeOffTerminationNotice',
                            :event_name => 'congress_employee_dependent_age_off_termination_notice',
                            :mpi_indicator => 'MPI_SHOPDPTC',
                            :title => "Change to your Insurance Coverage - Congressional"})
                          }

  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::CongressEmployeeDependentAgeOffTerminationNotice.new(census_employee, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::CongressEmployeeDependentAgeOffTerminationNotice.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::CongressEmployeeDependentAgeOffTerminationNotice.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::CongressEmployeeDependentAgeOffTerminationNotice.new(census_employee, valid_parmas)
    end
    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq census_employee.employee_role.person.full_name
      expect(@employee_notice.notice.employer_name).to eq census_employee.employer_profile.legal_name
    end
  end

  describe "append data" do
    before do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return enrollment
      allow(TimeKeeper).to receive(:date_of_record).and_return TimeKeeper.date_of_record.beginning_of_month
      allow(hbx_profile).to receive_message_chain(:benefit_sponsorship, :benefit_coverage_periods).and_return([bcp, renewal_bcp])
      @employee_notice = ShopEmployeeNotices::CongressEmployeeDependentAgeOffTerminationNotice.new(census_employee, valid_parmas)
    end

    it "should append data" do
      enrollment = census_employee.benefit_group_assignments.first.hbx_enrollment
      @employee_notice.append_data
      expect(@employee_notice.notice.enrollment.dependents).to eq family.family_members.where(is_primary_applicant: false).map(&:person).map(&:full_name)
      expect(@employee_notice.notice.enrollment.plan_year).to eq renewal_bcp.start_on.year
      expect(@employee_notice.notice.enrollment.effective_on).to eq renewal_bcp.start_on
      expect(@employee_notice.notice.enrollment.ivl_open_enrollment_start_on).to eq renewal_bcp.open_enrollment_start_on
      expect(@employee_notice.notice.enrollment.ivl_open_enrollment_end_on).to eq renewal_bcp.open_enrollment_end_on
    end

  end
end