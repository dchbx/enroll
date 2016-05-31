require "rails_helper"

RSpec.describe Employers::EmployerHelper, :type => :helper do
  describe "#enrollment_state" do

    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id) }
    let(:benefit_group_assignment) { double }
    let(:person) {double}
    let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:dental_plan) { FactoryGirl.create(:plan, coverage_kind: "dental", dental_level: "high" ) }
    let(:health_plan) { FactoryGirl.create(:plan, coverage_kind: "health") }
    let(:dental_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              employee_role_id: employee_role.id,
                                              coverage_kind: 'dental',
                                              plan: dental_plan
                                            )}
    let(:health_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              employee_role_id: employee_role.id,
                                              plan: health_plan
                                            )}

    before do
      allow(benefit_group_assignment).to receive(:aasm_state).and_return("coverage_selected")
      allow(census_employee).to receive(:employee_role).and_return(employee_role)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(employee_role).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(primary_family)
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
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Health)"
        end
      end

      context 'when dental coverage present' do
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([dental_enrollment])
        end

        it "should return dental enrollment status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Dental)"
        end
      end

      context 'when both health & dental coverage present' do
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment, dental_enrollment])
        end

        it "should return enrollment status for both health & dental" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Health)<Br/> Coverage Selected (Dental)"
        end
      end

      context 'when coverage terminated' do
        before do
          health_enrollment.terminate_coverage!
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment])
        end

        it "should return terminated status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Terminated (Health)"
        end
      end

      context 'when coverage waived' do
        before do
          health_enrollment.update_attributes(:aasm_state => :inactive)
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment])
        end

        it "should return terminated status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Waived (Health)"
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
  end
end
