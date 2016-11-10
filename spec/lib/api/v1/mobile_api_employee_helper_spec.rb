require "rails_helper"
require 'support/brady_bunch'


RSpec.describe Api::V1::EmployeeHelper, dbclean: :after_each do

  let!(:calendar_year) { TimeKeeper.date_of_record.year }
  let!(:effective_date) { Date.new(calendar_year, 1, 1) }
  let (:benefit_group) { FactoryGirl.create(:benefit_group, title: "Everyone") }
  let!(:shop_family) { FactoryGirl.create(:family, :with_primary_family_member) }

  [{id: :employee, text: "Robert Anson Heinlein Esq.", dob: "1907-07-07", ssn: "444556666", gender: "male", hired_on: "2008-12-08"},
   {id: :owner, text: "Virginia Doris Heinlein", dob: "1916-04-22", ssn: "111223333", gender: "female", hired_on: "2006-11-11"}
  ].each_with_index do |record, index|
    id = record[:id]
    first_name, middle_name, last_name, name_suffix = record[:text].split
    dob = record[:dob]
    ssn = record[:ssn]
    gender = record[:gender]
    hired_on = record[:hired_on]
    census_employee_id = "ce_#{id}".to_sym
    employee_role_id = "employee_role_#{id}".to_sym
    benefit_group_assignment_id = "benefit_group_assignment_#{id}".to_sym
    shop_enrollment_id = "shop_enrollment_#{id}".to_sym

    let!(id) {
      FactoryGirl.create(:person, first_name: first_name, middle_name: middle_name,
                         last_name: last_name, name_sfx: name_suffix,
                         dob: dob, ssn: ssn, gender: gender)
    }

    let!(census_employee_id) {
      FactoryGirl.create(:census_employee, first_name: first_name, middle_name: middle_name,
                         last_name: last_name, name_sfx: name_suffix,
                         dob: dob, ssn: ssn, gender: gender, hired_on: hired_on)
    }

    let!(employee_role_id) {
      send(record[:id]).employee_roles.create(
          employer_profile: FactoryGirl.create(:employer_profile),
          hired_on: hired_on,
          census_employee_id: send(census_employee_id).id
      )
    }

    let!(benefit_group_assignment_id) {
      BenefitGroupAssignment.create({
                                        census_employee: send(census_employee_id),
                                        benefit_group: benefit_group,
                                        start_on: Date.parse("2014-01-01")
                                    })
    }

    enrollments_by_kind = Hash[[:health, :dental].map do |coverage_kind|
      [coverage_kind, "#{shop_enrollment_id}_#{coverage_kind}".to_sym]
    end]

    all_enrollments = {}

    enrollments_by_kind.each do |coverage_kind, enrollment_id|
      let!(enrollment_id) {
        bga_id = send(benefit_group_assignment_id).id
        enrollment = FactoryGirl.create(:hbx_enrollment,
                                        household: shop_family.latest_household,
                                        coverage_kind: coverage_kind,
                                        effective_on: effective_date,
                                        enrollment_kind: "open_enrollment",
                                        kind: "employer_sponsored",
                                        submitted_at: effective_date - 10.days,
                                        benefit_group_id: benefit_group.id,
                                        employee_role_id: send(employee_role_id).id,
                                        benefit_group_assignment_id: bga_id,
                                        aasm_state: "coverage_enrolled"
        )

        all_enrollments[benefit_group_assignment_id] ||= []
        all_enrollments[benefit_group_assignment_id] << enrollment
        enrollment
      }
    end

    before do
      benefit_group_assignment = send(benefit_group_assignment_id)
      allow(send(employee_role_id)).to receive(:benefit_group).and_return(benefit_group_assignment.benefit_group)
      allow(send(census_employee_id)).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      enrollments_by_kind.values do |enrollment_id|
        allow(send(enrollment_id)).to receive(:employee_role).and_return(send(employee_role_id))
      end
      allow(send(benefit_group_assignment_id)).to receive(:hbx_enrollments).and_return(all_enrollments[benefit_group_assignment_id])
    end
  end


  context "Rendering employee" do
    it "should return the employee" do
      expect(ce_employee.active_benefit_group_assignment).to_not be nil
      expect(ce_employee.active_benefit_group_assignment.hbx_enrollments.count).to be > 0

      employee = Api::V1::EmployeeHelper.roster_employee ce_employee, true
      expect(employee).to include(:first_name, :middle_name, :last_name, :name_suffix, :gender, :date_of_birth,
                                  :ssn_masked, :hired_on, :id, :is_business_owner, :enrollments)
      expect(employee[:first_name]).to eq "Robert"
      expect(employee[:middle_name]).to eq "Anson"
      expect(employee[:last_name]).to eq "Heinlein"
      expect(employee[:name_suffix]).to eq "Esq."
      expect(employee[:gender]).to eq "male"
      expect(employee[:date_of_birth]).to eq Date.parse("1907-07-07")
      expect(employee[:ssn_masked]).to eq "***-**-6666"
      expect(employee[:hired_on]).to eq Date.parse("2008-12-08")
      expect(employee[:id]).to eq ce_employee.id
      expect(employee[:is_business_owner]).to be false

      expect(employee[:enrollments]).to be_a_kind_of Hash
      expect(employee[:enrollments]).to include(:renewal)
      expect(employee[:enrollments][:renewal]).to include('health', 'dental')
      expect(employee[:enrollments][:renewal]['health']).to include(:status)
      expect(employee[:enrollments][:renewal]['health'][:status]).to eq 'Not Enrolled'
      expect(employee[:enrollments][:renewal]['dental']).to include(:status)
      expect(employee[:enrollments][:renewal]['dental'][:status]).to eq 'Not Enrolled'
      expect(employee[:enrollments][:active]).to include('health', 'dental')
      health = employee[:enrollments][:active]["health"]
      expect(health).to_not be nil
      expect(health).to include(:status, :employer_contribution, :employee_cost, :total_premium, :plan_name, :plan_type,
                                :metal_level, :benefit_group_name)
      expect(health[:status]).to eq "Enrolled"

      dental = employee[:enrollments][:active]["dental"]
      expect(dental).to include(:status, :employer_contribution, :employee_cost, :total_premium, :plan_name, :plan_type,
                                :metal_level, :benefit_group_name)
    end
  end

end

