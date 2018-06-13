require "rails_helper"

RSpec.describe Employers::EmployerHelper, :type => :helper, dbclean: :after_each do
  describe "#enrollment_state" do

    let(:benefit_group)    { plan_year.benefit_groups.first }
    let(:plan_year)        do
      py = FactoryGirl.create(:plan_year_not_started)
      bg = FactoryGirl.create(:benefit_group, plan_year: py)
      PlanYear.find(py.id)
    end
    let(:employee_role) { FactoryGirl.create(:employee_role, person: person) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id) }
    let(:benefit_group_assignment) { double }
    let(:person) { FactoryGirl.create(:person, :with_ssn) }
    let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:dental_plan) { FactoryGirl.create(:plan, coverage_kind: "dental", dental_level: "high" ) }
    let(:health_plan) { FactoryGirl.create(:plan, coverage_kind: "health") }
    let(:dental_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              employee_role_id: employee_role.id,
                                              coverage_kind: 'dental',
                                              plan: dental_plan,
                                              benefit_group_id: benefit_group.id
                                            )}
    let(:health_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              employee_role_id: employee_role.id,
                                              plan: health_plan,
                                              benefit_group_id: benefit_group.id
                                            )}

    before do
      allow(benefit_group_assignment).to receive(:census_employee).and_return(census_employee)
      allow(benefit_group_assignment).to receive(:aasm_state).and_return("coverage_selected")
      allow(census_employee).to receive(:employee_role).and_return(employee_role)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(employee_role).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(primary_family)
    end

    context "census_employee states" do

      it "should return false for rehired state" do
        expect(helper.is_rehired(census_employee)).not_to be_truthy
      end

      it "should return false for terminated state" do
        expect(helper.is_terminated(census_employee)).not_to be_truthy
      end

      context "census_employee terminated state" do
        let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
        before do
          allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
          census_employee.terminate_employment!(TimeKeeper.date_of_record - 45.days)
        end

        it "should return true for terminated state" do
          expect(helper.is_terminated(census_employee)).to be_truthy
        end

        it "should return false for rehired state" do
          expect(helper.is_rehired(census_employee)).not_to be_truthy
        end
      end

      context "and the terminated employee is rehired" do
        let!(:census_employee) {
          ce = FactoryGirl.create(:census_employee, employee_role_id: employee_role.id)
          ce.terminate_employment!(TimeKeeper.date_of_record - 45.days)
          ce
        }
        let!(:rehired_census_employee) { census_employee.replicate_for_rehire }

        it "should return true for rehired state" do
          expect(helper.is_rehired(rehired_census_employee)).to be_truthy
        end
      end
    end

    context ".enrollment_state" do

      context 'when enrollments not present' do

        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([])
        end

        it "should return initialized as default" do
          expect(helper.enrollment_state(census_employee)).to be_blank
        end
      end

      context 'when health coverage present' do
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment])
        end

        it "should return health enrollment status" do
          expect(helper.enrollment_state(census_employee)).to eq "Enrolled (Health)"
        end
      end

      context 'when dental coverage present' do
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([dental_enrollment])
        end

        it "should return dental enrollment status" do
          expect(helper.enrollment_state(census_employee)).to eq "Enrolled (Dental)"
        end
      end

      context 'when both health & dental coverage present' do
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment, dental_enrollment])
        end

        it "should return enrollment status for both health & dental" do
          expect(helper.enrollment_state(census_employee)).to eq "Enrolled (Health)<Br/> Enrolled (Dental)"
        end
      end

      context 'when coverage terminated' do
        before do
          employee_role.update_attributes!(census_employee_id: census_employee.id)
          health_enrollment.terminate_coverage!
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment])
        end

        it "should return terminated status" do
          expect(helper.enrollment_state(census_employee)).to eq "Terminated (Health)"
        end
      end

      context 'when coverage waived' do
        before do
          health_enrollment.update_attributes(:aasm_state => :inactive)
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment])
        end

        it "should return terminated status" do
          expect(helper.enrollment_state(census_employee)).to eq "Waived (Health)"
        end
      end
    end


    context "return coverage kind for a census_employee" do
      it " when coverage kind is nil " do
        expect(helper.coverage_kind(nil)).to eq ""
      end

      it " when coverage kind is 'health' " do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([health_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health"
      end

      it " when coverage kind is 'dental' " do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([dental_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Dental"
      end

      # Tests the sort and reverse. Always want 'Health' before 'Dental'
      it " when coverage kind is 'health, dental' " do
        allow(primary_family).to receive(:enrolled_including_waived_hbx_enrollments).and_return([health_enrollment, dental_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health, Dental"
      end

      # Tests the sort and reverse. Always want 'Health' before 'Dental'
      it " when coverage kind is 'dental, health' " do
        allow(primary_family).to receive(:enrolled_including_waived_hbx_enrollments).and_return([dental_enrollment, health_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health, Dental"
      end
    end

    context "invoice_formated_date" do
      it "should return Month-Year format for a giving date" do
        expect(helper.invoice_formated_date(Date.new(2001,2,10))).to eq "02/10/2001"
        expect(helper.invoice_formated_date(Date.new(2016,4,14))).to eq "04/14/2016"
      end
    end

    context "invoice_coverage_date" do
      it "should return Month-Date-Year format for a giving date" do
        expect(helper.invoice_coverage_date(Date.new(2001,2,10))).to eq "Mar 2001"
        expect(helper.invoice_coverage_date(Date.new(2016,4,14))).to eq "May 2016"
      end
    end


    context ".get_benefit_groups_for_census_employee" do
      let(:health_plan)       { FactoryGirl.create(:plan, 
                                                   :with_premium_tables,
                                                   coverage_kind: "health",
                                                   active_year: TimeKeeper.date_of_record.year) }

      let(:expired_plan_year) { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month - 1.year,
                                                  end_on: TimeKeeper.date_of_record.beginning_of_month - 1.day,
                                                  aasm_state: 'expired') }

      let(:active_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'active') }

      let(:draft_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'draft') }

      let(:published_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'published') }

      let(:published_plan_year_with_terminated_on)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.year - 1.day,
                                                  terminated_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'published') }

      let(:renewing_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'renewing_draft') }


      let(:relationship_benefits) do
        [
          RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
          RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),    
          RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      let!(:employer_profile)  { FactoryGirl.create(:employer_profile, 
                                                    plan_years: [expired_plan_year, active_plan_year, draft_plan_year]) }

      let!(:employer_profile_1)  { FactoryGirl.create(:employer_profile)}

      before do 
        [expired_plan_year, active_plan_year, draft_plan_year, renewing_plan_year, published_plan_year].each do |py|
          bg = py.benefit_groups.build({
            title: 'DC benefits',
            plan_option_kind: "single_plan",
            effective_on_kind: 'first_of_month',
            effective_on_offset: 0,
            relationship_benefits: relationship_benefits,
            reference_plan_id: health_plan.id,
            })
          bg.elected_plans= [health_plan]
          bg.save!
        end
        assign(:employer_profile, employer_profile)
      end

      context "#show_or_hide_claim_quote_button" do
        it "should return true if plan year is in draft status" do
          employer_profile_1.update_attributes(plan_years: [draft_plan_year])
          expect(helper.show_or_hide_claim_quote_button(employer_profile_1)).to eq true
        end

        it "should return true if plan year is in renewing_draft status" do
          employer_profile_1.update_attributes(plan_years: [renewing_plan_year])
          expect(helper.show_or_hide_claim_quote_button(employer_profile_1)).to eq true
        end

        it "should return false if plan year is in published status" do
          employer_profile_1.update_attributes(plan_years: [published_plan_year])
          expect(helper.show_or_hide_claim_quote_button(employer_profile_1)).to eq false
        end

        it "should return false if plan year is in published status and with future terminated_on" do
          employer_profile_1.update_attributes(plan_years: [published_plan_year_with_terminated_on])
          expect(helper.show_or_hide_claim_quote_button(employer_profile_1)).to eq true
        end

        it "should return true if employer does not have any plan years" do
          expect(helper.show_or_hide_claim_quote_button(employer_profile_1)).to eq true
        end

        it "should return true if employer has both published and draft plan years" do
          employer_profile_1.update_attributes(plan_years: [draft_plan_year, published_plan_year])
          expect(helper.show_or_hide_claim_quote_button(employer_profile_1)).to eq true
        end
      end

      context "for employer with plan years" do
  
        it 'should not return expired benefit groups' do
          current_benefit_groups, renewal_benefit_groups = helper.get_benefit_groups_for_census_employee
          expect(current_benefit_groups.include?(expired_plan_year.benefit_groups.first)).to be_falsey
        end 

        it 'should return current benefit groups' do
          current_benefit_groups, renewal_benefit_groups = helper.get_benefit_groups_for_census_employee
          expect(current_benefit_groups.include?(active_plan_year.benefit_groups.first)).to be_truthy
          expect(current_benefit_groups.include?(draft_plan_year.benefit_groups.first)).to be_truthy
          expect(renewal_benefit_groups).to be_empty
        end
      end

      context 'for renewing employer' do 
        let!(:employer_profile)  { FactoryGirl.create(:employer_profile, 
                                    plan_years: [expired_plan_year, active_plan_year, draft_plan_year, renewing_plan_year]) }

        it 'should return both renewing and current benefit groups' do
          current_benefit_groups, renewal_benefit_groups = helper.get_benefit_groups_for_census_employee
          expect(current_benefit_groups.include?(active_plan_year.benefit_groups.first)).to be_truthy
          expect(current_benefit_groups.include?(draft_plan_year.benefit_groups.first)).to be_truthy
          expect(current_benefit_groups.include?(renewing_plan_year.benefit_groups.first)).to be_falsey
          expect(renewal_benefit_groups.include?(renewing_plan_year.benefit_groups.first)).to be_truthy
        end
      end

      context "for new initial employer" do
        let!(:employer_profile)  { FactoryGirl.create(:employer_profile, 
                                    plan_years: [draft_plan_year, published_plan_year]) }

        it 'should return upcoming draft and published plan year benefit groups' do
          current_benefit_groups, renewal_benefit_groups = helper.get_benefit_groups_for_census_employee
          expect(current_benefit_groups.include?(published_plan_year.benefit_groups.first)).to be_truthy
          expect(current_benefit_groups.include?(draft_plan_year.benefit_groups.first)).to be_truthy
          expect(renewal_benefit_groups).to be_empty
        end
      end
    end

    context "show_cobra_fields?" do
      let(:active_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'active') }
      let(:renewing_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'renewing_draft') }

      let(:employer_profile_with_active_plan_year) { FactoryGirl.create(:employer_profile, plan_years: [active_plan_year]) }
      let(:employer_profile_with_renewing_plan_year) { FactoryGirl.create(:employer_profile, plan_years: [active_plan_year, renewing_plan_year]) }
      let(:conversion_employer_profile_with_renewing_plan_year) { FactoryGirl.create(:employer_profile, profile_source: 'conversion', plan_years: [active_plan_year, renewing_plan_year]) }
      let(:employer_profile) { FactoryGirl.create(:employer_profile) }
      let(:user) { FactoryGirl.create(:user) }

      it "should return true when admin" do
        allow(user).to receive(:has_hbx_staff_role?).and_return true
        expect(helper.show_cobra_fields?(employer_profile, user)).to eq true
      end

      it "should return false when employer_profile without active_plan_year" do
        expect(helper.show_cobra_fields?(employer_profile, user)).to eq false
      end

      it "should return true when employer_profile with active_plan_year during open enrollment" do
        allow(active_plan_year).to receive(:open_enrollment_contains?).and_return true
        expect(helper.show_cobra_fields?(employer_profile_with_active_plan_year, user)).to eq true
      end

      it "should return false when employer_profile with active_plan_year not during open enrollment" do
        allow(active_plan_year).to receive(:open_enrollment_contains?).and_return false
        expect(helper.show_cobra_fields?(employer_profile_with_active_plan_year, user)).to eq false 
      end

      it "should return false when employer_profile is not conversion and with renewing" do
        expect(helper.show_cobra_fields?(employer_profile_with_renewing_plan_year, user)).to eq false 
      end

      it "should return false when employer_profile is conversion and has more than 2 plan_years" do
        conversion_employer_profile_with_renewing_plan_year.plan_years << active_plan_year
        expect(helper.show_cobra_fields?(conversion_employer_profile_with_renewing_plan_year, user)).to eq false 
      end
    end
  end
end
