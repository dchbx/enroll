require "rails_helper"
require 'support/brady_bunch'


RSpec.describe Api::V1::Mobile::Employer, dbclean: :after_each do

  context 'Enrollment Status' do
    let!(:employer_profile_cafe) { FactoryGirl.create(:employer_profile) }
    let!(:employer_profile_salon) { FactoryGirl.create(:employer_profile) }
    let!(:calender_year) { TimeKeeper.date_of_record.year }

    let!(:middle_of_prev_year) { Date.new(calender_year - 1, 6, 10) }

    let!(:shop_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:plan_year_start_on) { Date.new(calender_year, 1, 1) }
    let!(:plan_year_end_on) { Date.new(calender_year, 12, 31) }
    let!(:open_enrollment_start_on) { Date.new(calender_year - 1, 12, 1) }
    let!(:open_enrollment_end_on) { Date.new(calender_year - 1, 12, 10) }
    let!(:effective_date) { plan_year_start_on }

    ["cafe", "salon"].each do |id|
      employer_profile_id = "employer_profile_#{id}".to_sym
      plan_year_id = "plan_year_#{id}".to_sym
      let!(plan_year_id) {
        py = FactoryGirl.create(:plan_year,
                                start_on: plan_year_start_on,
                                end_on: plan_year_end_on,
                                open_enrollment_start_on: open_enrollment_start_on,
                                open_enrollment_end_on: open_enrollment_end_on,
                                employer_profile: send(employer_profile_id))

        blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
        white = FactoryGirl.build(:benefit_group, title: "white collar", plan_year: py)
        py.benefit_groups = [blue, white]
        py.save
        py.update_attributes({:aasm_state => 'published'})
        py
      }
    end


    [{id: :barista, name: 'John', coverage_kind: "health", works_at: 'cafe', collar: "blue"},
     {id: :manager, name: 'Grace', coverage_kind: "health", works_at: 'cafe', collar: "white"},
     {id: :janitor, name: 'Bob', coverage_kind: "dental", works_at: 'cafe', collar: "blue"},
     {id: :hairdresser, name: 'Tatiana', coverage_kind: "health", works_at: 'salon', collar: "blue"}
    ].each_with_index do |record, index|
      id = record[:id]
      name = record[:name]
      works_at = record[:works_at]
      coverage_kind = record[:coverage_kind]
      social_class = "#{record[:collar]} collar"
      employer_profile_id = "employer_profile_#{works_at}".to_sym
      plan_year_id = "plan_year_#{works_at}".to_sym
      census_employee_id = "census_employee_#{id}".to_sym
      employee_role_id = "employee_role_#{id}".to_sym
      benefit_group_assignment_id = "benefit_group_assignment_#{id}".to_sym
      shop_enrollment_id = "shop_enrollment_#{id}".to_sym
      get_benefit_group = -> (year) { year.benefit_groups.detect { |bg| bg.title == social_class } }

      let!(id) {
        FactoryGirl.create(:person, first_name: name, last_name: 'Smith',
                           dob: '1966-10-10'.to_date, ssn: rand.to_s[2..10])
      }

      let!(census_employee_id) {
        FactoryGirl.create(:census_employee, first_name: name, last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: "99966770#{index}", created_at: middle_of_prev_year, updated_at: middle_of_prev_year, hired_on: middle_of_prev_year)
      }

      let!(employee_role_id) {
        send(record[:id]).employee_roles.create(
            employer_profile: send(employer_profile_id),
            hired_on: send(census_employee_id).hired_on,
            census_employee_id: send(census_employee_id).id
        )
      }

      let!(benefit_group_assignment_id) {
        BenefitGroupAssignment.create({
                                          census_employee: send(census_employee_id),
                                          benefit_group: get_benefit_group.call(send(plan_year_id)),
                                          start_on: plan_year_start_on
                                      })
      }

      let!(shop_enrollment_id) {
        benefit_group = get_benefit_group.call(send(plan_year_id))
        bga_id = send(benefit_group_assignment_id).id
        FactoryGirl.create(:hbx_enrollment,
                           household: shop_family.latest_household,
                           coverage_kind: coverage_kind,
                           effective_on: effective_date,
                           enrollment_kind: "open_enrollment",
                           kind: "employer_sponsored",
                           submitted_at: effective_date - 10.days,
                           benefit_group_id: benefit_group.id,
                           employee_role_id: send(employee_role_id).id,
                           benefit_group_assignment_id: bga_id
        )
      }

      let!(:broker_role) { FactoryGirl.create(:broker_role) }
      let!(:person) { double("person", broker_role: broker_role, first_name: "Brunhilde") }
      let!(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false, :person => person) }
      let!(:organization) {
        o = FactoryGirl.create(:employer)
        a = o.primary_office_location.address
        a.address_1 = '500 Employers-Api Avenue'
        a.address_2 = '#555'
        a.city = 'Washington'
        a.state = 'DC'
        a.zip = '20001'
        o.primary_office_location.phone = Phone.new(:kind => 'main', :area_code => '202', :number => '555-9999')
        o.save
        o
      }
      let!(:broker_agency_profile) {
        profile = FactoryGirl.create(:broker_agency_profile, organization: organization)
        broker_role.broker_agency_profile_id = profile.id
        profile
      }
      let!(:broker_agency_account) {
        FactoryGirl.build(:broker_agency_account, broker_agency_profile: broker_agency_profile)
      }
      let (:employer_profile) do
        e = FactoryGirl.create(:employer_profile, organization: organization)
        e.broker_agency_accounts << broker_agency_account
        e.save
        e
      end

      before do
        benefit_group_assignment = send(benefit_group_assignment_id)
        allow(send(employee_role_id)).to receive(:benefit_group).and_return(benefit_group_assignment.benefit_group)
        allow(send(census_employee_id)).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
        allow(send(shop_enrollment_id)).to receive(:employee_role).and_return(send(employee_role_id))

        @employer = Api::V1::Mobile::Employer.new
      end
    end

    it 'counts by enrollment status' do
      result = @employer.send(:count_by_enrollment_status, employer_profile_cafe.show_plan_year)
      expect(result).to eq [2, 0, 0]

      result = @employer.send(:count_by_enrollment_status, employer_profile_salon.show_plan_year)
      expect(result).to eq [1, 0, 0]
    end

    it 'counts enrolled, waived and terminated employees' do
      result = @employer.send(:count_enrolled_waived_and_terminated_employees, employer_profile_cafe.show_plan_year)
      expect(result).to eq [2, 0, 0]

      result = @employer.send(:count_enrolled_waived_and_terminated_employees, employer_profile_salon.show_plan_year)
      expect(result).to eq [1, 0, 0]

      plan_year = Api::V1::Mobile::PlanYear.new plan_year: employer_profile_cafe.show_plan_year
      allow(plan_year).to receive(:plan_year_employee_max?).and_return(false)

      result = @employer.send(:count_enrolled_waived_and_terminated_employees, employer_profile_cafe.show_plan_year)
      expect(result).to eq [2, 0, 0]
    end

    it 'returns employer summaries' do
      employer = Api::V1::Mobile::Employer.new(employer_profiles: [employer_profile_cafe])
      summaries = employer.send(:marshall_employer_summaries)
      expect(summaries).to be_a_kind_of Array
      expect(summaries.size).to eq 1

      summary = summaries.first
      expect(summary).to include(:employer_name, :employees_total, #:employees_enrolled, :employees_waived,
                                 :open_enrollment_begins, :open_enrollment_ends, :plan_year_begins, :renewal_in_progress,
                                 :renewal_application_available, :renewal_application_due, :binder_payment_due,
                                 :minimum_participation_required, :contact_info, :employer_details_url,
                                 :employee_roster_url)

      expect(summary[:employer_name]).to eq 'Turner Agency, Inc'
      expect(summary[:open_enrollment_begins]).to eq Date.parse('2015-12-01')
      expect(summary[:open_enrollment_ends]).to eq Date.parse('2015-12-10')
      expect(summary[:plan_year_begins]).to eq Date.parse('2016-01-01')
      expect(summary[:renewal_application_available]).to eq Date.parse('2015-10-01')
      expect(summary[:renewal_application_due]).to eq Date.parse('2015-12-05')
      expect(summary[:renewal_in_progress]).to be_falsey
      expect(summary[:employees_total]).to eq 0
      expect(summary[:minimum_participation_required]).to eq 2
      expect(summary[:employer_details_url]).to include('/api/v1/mobile_api/employer_details/')
      expect(summary[:employee_roster_url]).to include('/api/v1/mobile_api/employee_roster/')

      contact_information = summary[:contact_info]
      expect(contact_information).to be_a_kind_of Array
      expect(contact_information.size).to eq 2

      expect(contact_information.pop).to include(:first, :last, :phone, :address_1, :address_2, :city, :state, :zip)
    end

    it 'returns employer details' do
      employer = Api::V1::Mobile::Employer.new employer_profile: employer_profile_cafe, report_date: TimeKeeper.date_of_record
      details = employer.details
      expect(details).to include(:employer_name, :employees_total, #:employees_enrolled, :employees_waived,
                                 :open_enrollment_begins, :open_enrollment_ends, :plan_year_begins, :renewal_in_progress,
                                 :renewal_application_available, :renewal_application_due, :binder_payment_due,
                                 # :employer_contribution, :employee_contribution, :total_premium, :employees_terminated,
                                 :minimum_participation_required, :active_general_agency)

      expect(details[:employer_name]).to eq 'Turner Agency, Inc'
      expect(details[:open_enrollment_begins]).to eq Date.parse('2015-12-01')
      expect(details[:open_enrollment_ends]).to eq Date.parse('2015-12-10')
      expect(details[:plan_year_begins]).to eq Date.parse('2016-01-01')
      expect(details[:renewal_application_available]).to eq Date.parse('2015-10-01')
      expect(details[:renewal_application_due]).to eq Date.parse('2015-12-05')
      expect(details[:renewal_in_progress]).to be_falsey
      expect(details[:employees_total]).to eq 0
      expect(details[:minimum_participation_required]).to eq 2

      expect(details[:plan_offerings]).to include(:active)
      expect(details[:plan_offerings][:active]).to be_a_kind_of Array
      active = details[:plan_offerings][:active].pop
      expect(active).to include(:benefit_group_name, :eligibility_rule, :health, :dental)

      expect(active[:benefit_group_name]).to eq 'white collar'
      expect(active[:eligibility_rule]).to eq 'First of the month following or coinciding with date of hire'
      expect(active[:health]).to include(:reference_plan_name, :reference_plan_HIOS_id, :carrier_name, :plan_type,
                                         :metal_level, :plan_option_kind)

      expect(active[:health][:reference_plan_name]).to include 'BLUECHOICE SILVER'
      expect(active[:health][:reference_plan_HIOS_id]).to include '41842DC04000'
      expect(active[:health][:carrier_name]).to eq 'United Health Care'
      expect(active[:health][:plan_type]).to eq 'HMO'
      expect(active[:health][:metal_level]).to eq 'Silver'
      expect(active[:health][:plan_option_kind]).to eq 'single_plan'

      expect(active[:health][:employer_contribution_by_relationship]).to include('employee', 'spouse', 'domestic_partner',
                                                                                 'child_under_26', 'disabled_child_26_and_over',
                                                                                 'child_26_and_over')
      expect(active[:health][:employer_contribution_by_relationship]['employee']).to eq 80.0
      expect(active[:health][:employer_contribution_by_relationship]['spouse']).to eq 40.0
      expect(active[:health][:employer_contribution_by_relationship]['domestic_partner']).to eq 40.0
      expect(active[:health][:employer_contribution_by_relationship]['child_under_26']).to eq 40.0
      expect(active[:health][:employer_contribution_by_relationship]['disabled_child_26_and_over']).to eq 40.0

      expect(active[:health][:estimated_employer_max_monthly_cost]).to eq 0.0
      expect(active[:health][:estimated_plan_participant_min_monthly_cost]).to eq 0.0
      expect(active[:health][:estimated_plan_participant_max_monthly_cost]).to eq 0.0
      expect(active[:health][:plans_by]).to eq 'A Single Plan'
      expect(active[:health][:plans_by_summary_text]).to eq 'Reference Plan Only'
    end

    it 'return employers and broker agency' do
      allow(Organization).to receive(:by_broker_agency_profile).and_return([organization])
      employer = Api::V1::Mobile::Employer.new authorized: {broker_agency_profile: broker_agency_profile, status: 200},
                                               user: user
      broker = employer.employers_and_broker_agency
      expect(broker).to include(:broker_name, :broker_agency, :broker_agency_id, :broker_clients)
      expect(broker[:broker_clients]).to be_a_kind_of Array
    end

    it 'returns benefit group assignments for plan year' do
      e = Api::V1::Mobile::Employee.new benefit_group: Api::V1::Mobile::BenefitGroup.new(plan_year: employer_profile_salon.show_plan_year)
      expect(e.send(:benefit_group_assignments)).to be_a_kind_of Array
      expect(e.send(:benefit_group_assignments).size).to eq 1
      expect(e.send(:benefit_group_assignments)).to eq [benefit_group_assignment_hairdresser]

      e = Api::V1::Mobile::Employee.new benefit_group: Api::V1::Mobile::BenefitGroup.new(plan_year: employer_profile_cafe.show_plan_year)
      expect(e.send(:benefit_group_assignments)).to be_a_kind_of Array
      expect(e.send(:benefit_group_assignments).size).to eq 3
      expect(e.send(:benefit_group_assignments)).to eq [benefit_group_assignment_barista, benefit_group_assignment_manager, benefit_group_assignment_janitor]
    end

  end

  context "Enrollment counts for various scenarios" do
    include_context "BradyWorkAfterAll"

    before :each do
      create_brady_census_families
    end

    attr_reader :enrollment, :household, :mikes_coverage_household, :carols_coverage_household, :coverage_household
    let!(:mikes_renewing_plan_year) { FactoryGirl.create(:renewing_plan_year, employer_profile: mikes_employer, benefit_groups: [mikes_benefit_group]) }

    before(:each) do
      @household = mikes_family.households.first
      @coverage_household1 = household.coverage_households[0]
      @coverage_household2= household.coverage_households[1]

      @enrollment1 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: @coverage_household1,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments
      )
      @enrollment1.save

      @enrollment2 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: @coverage_household2,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @carols_benefit_group_assignments
      )
      @enrollment2.save
    end


    it "should count enrollment for two waived in the same family" do
      @enrollment1.waive_coverage_by_benefit_group_assignment("inactive")
      @enrollment2.waive_coverage_by_benefit_group_assignment("inactive")
      benefit_group_assignment = [@mikes_benefit_group_assignments, @carols_benefit_group_assignments]
      employee = Api::V1::Mobile::Employee.new benefit_group_assignments: benefit_group_assignment
      result = employee.send(:count_by_enrollment_status)
      expect(result).to eq [0, 2, 0]
    end


    it "should count enrollment for two enrolled in the same family" do
      @enrollment1.update_attributes(aasm_state: "coverage_enrolled")
      @enrollment2.update_attributes(aasm_state: "coverage_enrolled")
      benefit_group_assignment = [@mikes_benefit_group_assignments, @carols_benefit_group_assignments]
      employee = Api::V1::Mobile::Employee.new benefit_group_assignments: benefit_group_assignment
      result = employee.send(:count_by_enrollment_status)
      expect(result).to eq [2, 0, 0]
    end


    it "should count enrollment for one enrolled and one waived in the same family" do
      @enrollment2.waive_coverage_by_benefit_group_assignment("inactive")
      @enrollment1.update_attributes(aasm_state: "coverage_enrolled")
      benefit_group_assignment = [@mikes_benefit_group_assignments, @carols_benefit_group_assignments]
      employee = Api::V1::Mobile::Employee.new benefit_group_assignments: benefit_group_assignment
      result = employee.send(:count_by_enrollment_status)
      expect(result).to eq [1, 1, 0]
    end

    it "people with shopped-for-but-not-bought or terminated policies" do
      @enrollment2.update_attributes(aasm_state: "coverage_terminated")
      benefit_group_assignment = [@mikes_benefit_group_assignments, @carols_benefit_group_assignments]
      employee = Api::V1::Mobile::Employee.new benefit_group_assignments: benefit_group_assignment
      result = employee.send(:count_by_enrollment_status)
      expect(result).to eq [0, 0, 1]
    end

    it "Should count enrollment for the person not enrolled this year but already enrolled for next year if looking at next year" do
      @mikes_benefit_group_assignments.update_attributes(start_on: mikes_renewing_plan_year.start_on, aasm_state: "coverage_renewed")
      @household = mikes_family.households.first
      @coverage_household1 = household.coverage_households[0]

      @enrollment1 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: @coverage_household1,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments,
      )
      @enrollment1.save
      @enrollment1.update_attributes(aasm_state: "renewing_coverage_enrolled")


      benefit_group_assignment = [@mikes_benefit_group_assignments]
      employee = Api::V1::Mobile::Employee.new benefit_group_assignments: benefit_group_assignment
      result = employee.send(:count_by_enrollment_status)
      expect(result).to eq [0, 0, 0]
    end

    it "Should count enrollment for person enrolled this year but already waived for next year if looking at next year" do
      @household = mikes_family.households.first
      @coverage_household1 = household.coverage_households[0]

      @enrollment1 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: @coverage_household1,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments,
      )
      @enrollment1.save
      @enrollment1.waive_coverage_by_benefit_group_assignment("inactive")


      benefit_group_assignment = [@mikes_benefit_group_assignments]
      employee = Api::V1::Mobile::Employee.new benefit_group_assignments: benefit_group_assignment
      result = employee.send(:count_by_enrollment_status)
      expect(result).to eq [0, 0, 0]

    end
  end

end

