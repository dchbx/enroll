require "rails_helper"
require 'support/brady_bunch'
require 'lib/api/v1/support/mobile_employer_data'

RSpec.describe Api::V1::Mobile::Employer, dbclean: :after_each do
  include_context 'employer_data'

  shared_examples 'organizations_by' do |desc|
    it "should #{desc}" do
      organizations = employer.send(:organizations)
      expect(organizations).to be_a_kind_of Mongoid::Criteria
      org = organizations.first
      expect(org).to be_a_kind_of Organization
      expect(org.hbx_id).to_not be_nil
      expect(org.legal_name).to_not be_nil
      expect(org.fein).to_not be_nil
      expect(org.dba).to_not be_nil
    end
  end

  context 'Enrollment Status' do

    it 'initializes the plan year' do
      allow(employer_profile).to receive(:show_plan_year).and_return(employer_profile_cafe.show_plan_year)
      employer = Api::V1::Mobile::Employer.new user: user, employer_profile: employer_profile
      plan_year = employer.instance_variable_get(:@plan_year)
      expect(plan_year).to_not be_nil
      expect(plan_year).to be_a_kind_of PlanYear
    end

    it_behaves_like 'organizations_by', 'get organization by broker agency profile' do
      let!(:employer) {
        allow(employer_profile).to receive(:broker_agency_accounts).and_return([broker_agency_account])
        Api::V1::Mobile::Employer.new user: user, authorized: {broker_agency_profile: broker_agency_profile}
      }
    end

    it_behaves_like 'organizations_by', 'get organization by broker role' do
      let!(:employer) {
        allow(employer_profile2).to receive(:broker_agency_accounts).and_return([broker_agency_account2])
        Api::V1::Mobile::Employer.new user: user, authorized: {broker_role: broker_role}
      }
    end

    it 'should return the active and renewal plan years' do
      employer = Api::V1::Mobile::Employer.new user: user, employer_profile: employer_profile
      allow(employer_profile).to receive(:plan_years).and_return([employer_profile_cafe.show_plan_year])
      plan_years = employer.send(:active_and_renewal_plan_years)
      expect(plan_years).to be_a_kind_of Hash
      expect(plan_years).to have_key(:active)
      expect(plan_years).to have_key(:renewal)

      active = plan_years[:active]
      expect(active).to be_a_kind_of PlanYear
      expect(active.open_enrollment_start_on).to eq employer_profile_cafe.show_plan_year.open_enrollment_start_on
      expect(active.open_enrollment_end_on).to eq employer_profile_cafe.show_plan_year.open_enrollment_end_on
    end

    it 'should count by open enrollment status' do
      employer = Api::V1::Mobile::Employer.new user: user, employer_profile: employer_profile
      result = employer.send(:open_enrollment_employee_count, employer_profile_cafe.show_plan_year, Time.now - (1*365*24*60*60))
      expect(result).to be_nil
      result = employer.send(:open_enrollment_employee_count, employer_profile_cafe.show_plan_year, Time.now)
      expect(result).to eq [2, 0, 0]
    end


    it 'should return the summary details' do
      employer = Api::V1::Mobile::Employer.new user: user, employer_profile: employer_profile
      summary = employer.send(:summary_details, {employer_profile: employer_profile, year: employer_profile_cafe.show_plan_year})
      expect(summary).to include(:employer_name, :binder_payment_due, :employees_total, :minimum_participation_required,
                                 :open_enrollment_begins, :open_enrollment_ends, :plan_year_begins, :renewal_application_available,
                                 :renewal_application_due, :renewal_in_progress)
      expect(summary[:open_enrollment_begins]).to eq Date.parse('2016-11-01')
      expect(summary[:open_enrollment_ends]).to eq Date.parse('2016-12-10')
      expect(summary[:plan_year_begins]).to eq Date.parse('2017-01-01')
      expect(summary[:renewal_application_available]).to eq Date.parse('2016-10-01')
      expect(summary[:renewal_application_due]).to eq Date.parse('2016-12-05')
      expect(summary[:renewal_in_progress]).to be_falsey
      expect(summary[:employees_total]).to eq 0
      expect(summary[:minimum_participation_required]).to eq 2

      summary = employer.send(:summary_details, {employer_profile: employer_profile, year: employer_profile_cafe.show_plan_year,
                                                 num_enrolled: 2, num_waived: 1, num_terminated: 3})
      expect(summary[:employees_enrolled]).to eq 2
      expect(summary[:employees_waived]).to eq 1
      expect(summary[:employees_terminated]).to eq 3

      summary = employer.send(:summary_details, {employer_profile: employer_profile, year: employer_profile_cafe.show_plan_year,
                                                 staff: [FactoryGirl.create(:person)], offices: [FactoryGirl.build(:office_location)]})
      expect(summary).to include(:contact_info)
      contact_info = summary[:contact_info]
      expect(contact_info).to be_a_kind_of Array
      expect(contact_info.size).to eq 2
      offices = contact_info.pop
      staff = contact_info.pop
      expect(staff).to include(:first, :last, :phone, :mobile, :emails)
      expect(offices).to include(:first, :last, :phone, :address_1, :address_2, :city, :state, :zip)
      expect(staff[:emails]).to be_a_kind_of Array
      expect(staff[:first]).to_not be_nil
      expect(staff[:last]).to_not be_nil
      expect(offices[:first]).to_not be_nil
      expect(offices[:last]).to_not be_nil
      expect(offices[:phone]).to_not be_nil
      expect(offices[:address_1]).to_not be_nil
      expect(offices[:address_2]).to_not be_nil
      expect(offices[:city]).to_not be_nil
      expect(offices[:state]).to_not be_nil
      expect(offices[:zip]).to_not be_nil
    end

    it 'should add the URLs to the summary' do
      employer = Api::V1::Mobile::Employer.new user: user, employer_profile: employer_profile
      summary = {}
      employer.send(:add_urls!, employer_profile, summary)
      expect(summary).to include(:employer_details_url, :employee_roster_url)
      expect(summary[:employer_details_url]).to include('/api/v1/mobile_api/employer_details/')
      expect(summary[:employee_roster_url]).to include('/api/v1/mobile_api/employee_roster/')
    end

    it 'should return the details' do
      allow(employer_profile).to receive(:show_plan_year).and_return(employer_profile_cafe.show_plan_year)
      employer = Api::V1::Mobile::Employer.new user: user, employer_profile: employer_profile,
                                               plan_year: employer_profile_cafe.show_plan_year
      summary = employer.details
      expect(summary).to include(:employer_name, :binder_payment_due, :employees_total, :minimum_participation_required,
                                 :open_enrollment_begins, :open_enrollment_ends, :plan_year_begins, :renewal_application_available,
                                 :renewal_application_due, :renewal_in_progress, :plan_offerings)
      expect(summary[:plan_offerings]).to include(:active, :renewal)
      expect(summary[:open_enrollment_begins]).to eq Date.parse('2016-11-01')
      expect(summary[:open_enrollment_ends]).to eq Date.parse('2016-12-10')
      expect(summary[:plan_year_begins]).to eq Date.parse('2017-01-01')
      expect(summary[:renewal_application_available]).to eq Date.parse('2016-10-01')
      expect(summary[:renewal_application_due]).to eq Date.parse('2016-12-05')
      expect(summary[:renewal_in_progress]).to be_falsey
      expect(summary[:employees_total]).to eq 0
      expect(summary[:minimum_participation_required]).to eq 2
    end

    it 'counts by enrollment status' do
      mobile_plan_year = Api::V1::Mobile::PlanYear.new plan_year: employer_profile_cafe.show_plan_year
      result = @employer.send(:count_by_enrollment_status, mobile_plan_year)
      expect(result).to eq [2, 0, 0]

      mobile_plan_year = Api::V1::Mobile::PlanYear.new plan_year: employer_profile_salon.show_plan_year
      result = @employer.send(:count_by_enrollment_status, mobile_plan_year)
      expect(result).to eq [1, 0, 0]
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
      expect(summary[:open_enrollment_begins]).to eq Date.parse('2016-11-01')
      expect(summary[:open_enrollment_ends]).to eq Date.parse('2016-12-10')
      expect(summary[:plan_year_begins]).to eq Date.parse('2017-01-01')
      expect(summary[:renewal_application_available]).to eq Date.parse('2016-10-01')
      expect(summary[:renewal_application_due]).to eq Date.parse('2016-12-05')
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
      expect(details[:open_enrollment_begins]).to eq Date.parse('2016-11-01')
      expect(details[:open_enrollment_ends]).to eq Date.parse('2016-12-10')
      expect(details[:plan_year_begins]).to eq Date.parse('2017-01-01')
      expect(details[:renewal_application_available]).to eq Date.parse('2016-10-01')
      expect(details[:renewal_application_due]).to eq Date.parse('2016-12-05')
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

