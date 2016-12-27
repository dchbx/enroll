require 'rails_helper'

RSpec.describe Factories::FamilyEnrollmentRenewalFactory, :type => :model do

  context 'Family under renewing employer' do

    let(:renewal_year) { (TimeKeeper.date_of_record.end_of_month + 1.day + 2.months).year }

    let!(:renewal_plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: renewal_year, hios_id: "11111111122302-01", csr_variant_id: "01")
    }

    let!(:plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: renewal_year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id)
    }

    let!(:organization) { 
      org = FactoryGirl.create :organization, legal_name: "Corp 1" 
      employer_profile = FactoryGirl.create :employer_profile, organization: org
      FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
      org.reload
    }

    let(:employer_profile) { organization.employer_profile }

    let!(:build_plan_years_and_employees) {
      owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
      employee = FactoryGirl.create :census_employee, employer_profile: employer_profile

      benefit_group = FactoryGirl.create :benefit_group, plan_year: active_plan_year, reference_plan_id: plan.id
      employee.add_benefit_group_assignment benefit_group, benefit_group.start_on

      employee.add_renew_benefit_group_assignment renewal_benefit_group
    }
      
    let(:open_enrollment_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day }
    let(:open_enrollment_end_on) { open_enrollment_start_on.next_month + 12.days }
    let(:start_on) { open_enrollment_start_on + 2.months }
    let(:end_on) { start_on + 1.year - 1.day }
  
    let(:active_plan_year) {
      FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on - 1.year, end_on: end_on - 1.year, open_enrollment_start_on: open_enrollment_start_on - 1.year, open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days, fte_count: 2, aasm_state: :published
    }

    let(:renewing_plan_year) {
      FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on, fte_count: 2, aasm_state: :renewing_draft
    }

    let(:renewal_benefit_group){
      FactoryGirl.create :benefit_group, plan_year: renewing_plan_year, reference_plan_id: renewal_plan.id
    }

    let!(:ce) {
      organization.employer_profile.census_employees.non_business_owner.first
    }


    let(:generate_passive_renewal) {
      factory = Factories::FamilyEnrollmentRenewalFactory.new
      factory.family = family
      factory.census_employee = ce
      factory.employer = employer_profile
      factory.renewing_plan_year = employer_profile.renewing_plan_year
      factory.renew
    }

    context 'with active coverage' do 

      let!(:family) {
        person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: organization.employer_profile)
        ce.update_attributes({employee_role: employee_role})
        family_rec = Family.find_or_build_from_employee_role(employee_role)

        FactoryGirl.create(:hbx_enrollment,
          household: person.primary_family.active_household,
          coverage_kind: "health",
          effective_on: ce.active_benefit_group_assignment.benefit_group.start_on,
          enrollment_kind: "open_enrollment",
          kind: "employer_sponsored",
          submitted_at: ce.active_benefit_group_assignment.benefit_group.start_on - 20.days,
          benefit_group_id: ce.active_benefit_group_assignment.benefit_group.id,
          employee_role_id: person.active_employee_roles.first.id,
          benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
          plan_id: plan.id
          )

        family_rec.reload
      }

      context 'when employer offering the renewing plan' do 
        it 'should receive passive renewal' do 
          expect(family.enrollments.size).to eq 1
          expect(family.enrollments.map(&:aasm_state)).not_to include('auto_renewing')
          generate_passive_renewal
          expect(family.enrollments.size).to eq 2
          expect(family.enrollments.map(&:aasm_state)).to include('auto_renewing')
          expect(family.enrollments.renewing.first.plan).to eq renewal_plan
        end
      end

      context 'when employer changed plan offerings for renewing plan year' do

        let!(:new_renewal_plan) {
          FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: renewal_year, hios_id: "11111111122301-01", csr_variant_id: "01")
        }

        let(:renewal_benefit_group){
          FactoryGirl.create :benefit_group, plan_year: renewing_plan_year, reference_plan_id: new_renewal_plan.id
        }

        it 'should not recive passive renewal' do
          expect(family.enrollments.size).to eq 1
          expect(family.enrollments.map(&:aasm_state)).not_to include('auto_renewing')
          generate_passive_renewal
          expect(family.enrollments.size).to eq 1
          expect(family.enrollments.map(&:aasm_state)).not_to include('auto_renewing')
        end
      end
    end

    context 'with no active coverage' do 

      let!(:family) {
        person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: organization.employer_profile)
        ce.update_attributes({employee_role: employee_role})
        family_rec = Family.find_or_build_from_employee_role(employee_role)

        FactoryGirl.create(:hbx_enrollment,
          household: person.primary_family.active_household,
          coverage_kind: "health",
          effective_on: ce.active_benefit_group_assignment.benefit_group.start_on,
          enrollment_kind: "open_enrollment",
          kind: "employer_sponsored",
          submitted_at: ce.active_benefit_group_assignment.benefit_group.start_on - 20.days,
          benefit_group_id: ce.active_benefit_group_assignment.benefit_group.id,
          employee_role_id: person.active_employee_roles.first.id,
          benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
          plan_id: plan.id,
          terminated_on: ce.active_benefit_group_assignment.benefit_group.start_on + 2.months,
          aasm_state: 'coverage_terminated'
          )

        family_rec.reload
      }

      context 'when employer enters renewal open enrollment' do

        it 'should recieve passive waiver' do 
          expect(family.active_household.hbx_enrollments.size).to eq 1
          expect(family.active_household.hbx_enrollments.first.aasm_state).to eq 'coverage_terminated'
          generate_passive_renewal
          family.reload
          expect(family.active_household.hbx_enrollments.size).to eq 2
          expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to include('renewing_waived')
        end
      end
    end

    # context 'with waived coverage' do

    #   let!(:family) {
    #     person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    #     employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: organization.employer_profile)
    #     ce.update_attributes({employee_role: employee_role})
    #     family_rec = Family.find_or_build_from_employee_role(employee_role)
    #     family_rec.reload
    #   }

    #   context 'when employer enters renewal open enrollment' do 
    #     it 'should recieve passive waiver' do
    #       expect(family.active_household.hbx_enrollments.size).to eq 0
    #       generate_passive_renewal
    #       family.reload
    #       expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to include('renewing_waived')
    #     end
    #   end
    # end
    
    context 'with no active/waived coverage' do 

      let!(:family) {
        person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: organization.employer_profile)
        ce.update_attributes({employee_role: employee_role})
        family_rec = Family.find_or_build_from_employee_role(employee_role)
        family_rec.reload
      }

      context 'when employer enters renewal open enrollment' do 
        it 'should recieve passive waiver' do
          expect(family.active_household.hbx_enrollments.size).to eq 0
          generate_passive_renewal
          family.reload
          expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to include('renewing_waived')
        end
      end
    end

    context ".renewal_relationship_benefits" do
      let(:census_employee) {FactoryGirl.create(:census_employee)}
      let(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee)}
      let(:person) { FactoryGirl.create(:person)}
      let!(:shop_family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }
      let!(:auto_renewing_health_enrollment)   { FactoryGirl.create(:hbx_enrollment,
                                                                    household: shop_family.latest_household,
                                                                    coverage_kind: "health",
                                                                    kind: "employer_sponsored")}
      let!(:auto_renewing_dental_enrollment)   { FactoryGirl.create(:hbx_enrollment,
                                                                    household: shop_family.latest_household,
                                                                    coverage_kind: "dental",
                                                                    kind: "employer_sponsored")}
      let(:health_relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
            RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end
      let(:dental_relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
            RelationshipBenefit.new(offered: false, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      before :each do
        subject.instance_variable_set(:@census_employee, census_employee)
        allow(census_employee).to receive(:renewal_benefit_group_assignment).and_return benefit_group_assignment
        allow(benefit_group_assignment).to receive(:benefit_group).and_return renewal_benefit_group
        allow(renewal_benefit_group).to receive(:relationship_benefits).and_return health_relationship_benefits
        allow(renewal_benefit_group).to receive(:dental_relationship_benefits).and_return dental_relationship_benefits
      end

      it "should return offered health_relationship_benefits of renewal benefit group" do
        expect(subject.renewal_relationship_benefits(auto_renewing_health_enrollment)).to eq ["employee","spouse","child_under_26"]
      end

      it "should return offered dental_relationship_benefits of renewal benefit group" do
        expect(subject.renewal_relationship_benefits(auto_renewing_dental_enrollment)).to eq ["employee", "spouse"]
      end
    end

    context "is_relationship_offered_and_member_covered?" do
      let(:orb) {["employee", "spouse", "child_under_26"]}
      let(:spouse) { double(primary_relationship: "ex-spouse")}
      let(:employee) { double(primary_relationship: "self")}
      let(:domestic_partner) { double(primary_relationship: "life_partner") }
      let(:person1) {FactoryGirl.create(:person)}
      let(:person2) {FactoryGirl.create(:person,dob: TimeKeeper.date_of_record - 20.years)}
      let(:child) {double(primary_relationship: "ward")}
      let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
      let!(:plan_year_start_on) {TimeKeeper.date_of_record}
      before :each do
        allow(subject).to receive(:renewal_relationship_benefits).and_return orb
        plan_year_start_on = TimeKeeper.date_of_record
        subject.instance_variable_set(:@plan_year_start_on, plan_year_start_on)
      end

      it "should return true if spouse relationship offered and covered in active enrollment" do
        allow(spouse).to receive(:is_covered_on?).and_return(true)
        expect(subject.is_relationship_offered_and_member_covered?(spouse,benefit_group)).to be_truthy
      end

      it "should return false if domestic_partner relationship not offered" do
        allow(domestic_partner).to receive(:is_covered_on?).and_return(true)
        expect(subject.is_relationship_offered_and_member_covered?(domestic_partner,benefit_group)).to be_falsey
      end

      it "should return true if employee relationship offered and covered in active enrollment" do
        allow(employee).to receive(:is_covered_on?).and_return(true)
        expect(subject.is_relationship_offered_and_member_covered?(employee,benefit_group)).to be_truthy
      end

      it "should return false if relationship is child_over_26" do
        allow(child).to receive(:is_covered_on?).and_return(true)
        allow(child).to receive(:person).and_return person1
        expect(subject.is_relationship_offered_and_member_covered?(child,benefit_group)).to be_falsey
      end

      it "should return true if child relationship(child_under_26) offered and covered in active enrollment" do
        allow(child).to receive(:is_covered_on?).and_return(true)
        allow(child).to receive(:person).and_return person2
        expect(subject.is_relationship_offered_and_member_covered?(child,benefit_group)).to be_truthy
      end
    end

    context "clone_enrollment_members" do
      let(:person) { FactoryGirl.build_stubbed(:person)}
      let(:family) { FactoryGirl.build_stubbed(:family, :with_primary_family_member, person: person) }
      let(:household) { FactoryGirl.build_stubbed(:household, family: family) }
      let(:active_enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household, hbx_enrollment_members: [hbx_enrollment_member, hbx_enrollment_member_two]) }
      let(:hbx_enrollment_member) { FactoryGirl.build_stubbed(:hbx_enrollment_member) }
      let(:hbx_enrollment_member_two) { FactoryGirl.build_stubbed(:hbx_enrollment_member, is_subscriber: false) }


      let(:renewal_enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household) }

      it "should return hbx_enrollment_members if member relationship offered in renewal plan year and covered in current hbx_enrollment" do
        allow(subject).to receive(:is_relationship_offered_and_member_covered?).and_return(true)
        expect(subject.clone_enrollment_members(active_enrollment, renewal_enrollment).length).to eq 2
      end

      it "should not return hbx_enrollment_members if member relationship not offered in renewal plan year" do
        allow(subject).to receive(:is_relationship_offered_and_member_covered?).and_return(false)
        expect(subject.clone_enrollment_members(active_enrollment, renewal_enrollment).length).to eq 0
      end
    end
  end
end
