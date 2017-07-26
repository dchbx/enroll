require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "expire_conversion_employers")

describe ExpireConversionEmployers, dbclean: :after_each do

  let(:given_task_name) { "expire_conversion_employers" }
  subject { ExpireConversionEmployers.new(given_task_name, double(:current_scope => nil)) }

  context "conversion employer" do
    let(:organization) {
      org = create(:organization, :with_expired_and_active_plan_years)
      org.employer_profile.update!(profile_source: 'conversion', registered_on: org.employer_profile.active_plan_year.start_on - 3.months)
      org.employer_profile.plan_years.expired.first.update(is_conversion: true)
      org
    }

    let(:employer_profile) {
      organization.employer_profile
    }

    let(:benefit_group) { organization.employer_profile.active_plan_year.benefit_groups.first }
    let!(:benefit_group_assignment) { build(:benefit_group_assignment, benefit_group: benefit_group) }
    let!(:census_employee) { create(:census_employee,
      employer_profile: organization.employer_profile,
      benefit_group_assignments: [benefit_group_assignment]
      ) }

    let!(:person) { create(:person) }
    let!(:employee_role) { person.employee_roles.create( employer_profile: organization.employer_profile, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
    let!(:shop_family)       { create(:family, :with_primary_family_member, :person => person) }

    let!(:health_enrollment)   { create(:hbx_enrollment,
      household: shop_family.latest_household,
      coverage_kind: "health",
      effective_on: benefit_group.start_on,
      enrollment_kind: "open_enrollment",
      kind: "employer_sponsored",
      submitted_at: benefit_group.start_on - 1.month,
      benefit_group_id: benefit_group.id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: benefit_group_assignment.id
      )
    }

    it 'should cancel enrollments' do
      subject.update_employer_plan_years(employer_profile, benefit_group.start_on)
      health_enrollment.reload
      expect(health_enrollment.coverage_canceled?).to be_truthy
    end

    it 'should cancel renewal plan year' do
      subject.update_employer_plan_years(employer_profile, benefit_group.start_on)
      expect(employer_profile.plan_years.where(:start_on => benefit_group.start_on).first.renewing_canceled?).to be_truthy
    end

    it 'should conversion expire external plan year' do
      subject.update_employer_plan_years(employer_profile, benefit_group.start_on)
      expect(employer_profile.plan_years.where(:start_on => (benefit_group.start_on - 1.year)).first.conversion_expired?).to be_truthy
    end
  end
end
