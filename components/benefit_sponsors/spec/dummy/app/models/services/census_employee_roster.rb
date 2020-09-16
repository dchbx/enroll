# frozen_string_literal: true

module Services
  class CensusEmployeeRoster
    include ActionView::Helpers::NumberHelper

    attr_reader :employer_profile, :site_key
    attr_accessor :headers, :type_of_action, :dep_count

    def initialize(employer_profile, options = {})
      @employer_profile = employer_profile
      @site_key = fetch_site_key
      @dep_count = dependent_count
      @type_of_action = options[:action]
      @headers = config_based_headers
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << (["#{Settings.site.long_name} Employee Census Template"] + Array.new(6) + [TimeKeeper.date_of_record] + Array.new(5) + ['1.1'])
        csv << headers
        census_employee_roster.each do |census_employee|
          personal_details = personal_headers(census_employee)
          employee_details = employeement_headers(census_employee)
          benefit_group_details = benefit_group_assignment_details(census_employee)
          address_details = primary_location_details(census_employee)
          append_config_data = ['', 'employee'] + personal_details + employee_details + benefit_group_details + address_details

          if site_key == :dc
            @total_employer_contribution = total_premium(census_employee) #Using pipe, as the contribution is same in every loop, this does not work for employee premium.
            append_config_data += @total_employer_contribution
            census_employee.census_dependents.each do |dependent|
              append_config_data += append_dependent(dependent)
            end
          end

          csv << append_config_data
        end
      end
    end

    def benefit_group_assignment_details(census_employee)
      bga = []
      active_assignment = census_employee.active_benefit_group_assignment
      if active_assignment
        health_enrollment = pull_enrollment_state_by_kind(active_assignment, 'health')
        dental_enrollment = pull_enrollment_state_by_kind(active_assignment, 'dental')
        bga.push(
            active_assignment.benefit_package.title,
            "dental: #{dental_enrollment}  health: #{health_enrollment}",
            active_assignment.try(:benefit_application).try(:start_on)
        )
      else
        bga += Array.new(3)
      end
      bga
    end

    def pull_enrollment_state_by_kind(active_bga, coverage_kind)
      active_bga.try(:hbx_enrollments).detect {|enrollment| enrollment.coverage_kind == coverage_kind}.try(:aasm_state).try(:humanize).try(:downcase)
    end

    def total_premium(record)
      return @total_employer_contribution if @total_employer_contribution&.any?

      if record.is_a?(::SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee)
        bqt_estimated_premium
      elsif (bga = record.active_benefit_group_assignment)
        employer_estimated_premium(bga)
      else
        Array.new(2)
      end
    end

    def employer_estimated_premium(bga)
      premiums = []
      estimator = ::BenefitSponsors::Services::SponsoredBenefitCostEstimationService.new
      bga.benefit_package.sponsored_benefits.each do |sponsored_benefit|
        #As per the current requirement, total premium for the employer is calculated and recorded in the excel.
        cost_hash = estimator.calculate_estimates_for_benefit_display(sponsored_benefit)
        premiums.push(number_to_currency(cost_hash ? cost_hash[:estimated_sponsor_exposure] : 0))
      end

      # handles Only health/dental present or none
      premiums += Array.new(2 - premiums.count)
    end

    private

    def primary_location_details(record)
      if record.address.present?
        record.address.to_a
      else
        Array.new(6)
      end
    end

    def employeement_headers(census_employee)
      employeement = []
      employeement.push(
          census_employee.hired_on.present? ? census_employee.hired_on.strftime('%m/%d/%Y') : '',
          census_employee.aasm_state.humanize.downcase,
          census_employee.employment_terminated_on.present? ? census_employee.employment_terminated_on.strftime('%m/%d/%Y') : '',
          census_employee.is_business_owner ? 'yes' : 'no'
      )
      employeement
    end

    def personal_headers(record)
      personal_info_headers = []
      primary_attributes.each do |attribute|
        personal_info_headers.push record.send(attribute)
      end
      personal_info_headers
    end

    def dependent_headers(type_of_action)
      return [] if type_of_action == 'upload'

      dep_headers = []
      dep_count.times do |i|
        dependent_attributes.each do |attribute|
          dep_headers << "Dep#{i + 1} #{attribute.titleize}"
        end
      end
      dep_headers
    end

    def append_dependent(dependent)
      columns = []
      dependent_attributes.each do |attribute|
        columns.push(dependent.public_send(attribute).presence ? dependent.public_send(attribute) : '')
      end
      columns
    end

    def dependent_count
      dependent = []
      census_employee_roster.each do |census_employee|
        next if census_employee.census_dependents.blank?

        dependent.push census_employee.census_dependents.count
      end
      dependent.max.nil? ? 0 : dependent.max
    end

    def config_based_headers
      site_key == :dc ? dc_csv_headers : census_employee_details_headers
    end

    def dc_csv_headers
      census_employee_details_headers + contribution_headers + dependent_headers(type_of_action)
    end

    def census_employee_details_headers
      [
          'Family ID # (to match family members to the EE & each household gets a unique number)(Optional)',
          'Relationship (EE, Spouse, Domestic Partner, or Child)',
          'Last Name',
          'First Name',
          'Middle Name or Initial (Optional)',
          'Suffix (Optional)',
          'Email Address',
          'SSN / TIN (Required for EE & enter without dashes)',
          'Date of Birth (MM/DD/YYYY)',
          'Gender',
          'Date of Hire',
          'Status(Optional)',
          'Date of Termination (Optional)',
          'Is Business Owner?',
          'Benefit Group(Optional)',
          'Enrollment Type(Optional)',
          'Plan Year (Optional)',
          'Address Kind(Optional)',
          'Address Line 1(Optional)',
          'Address Line 2(Optional)',
          'City(Optional)',
          'State(Optional)',
          'Zip(Optional)'
      ]
    end

    def contribution_headers
      %w[Total\ Monthly\ Premium\ Health Total\ Monthly\ Premium\ Dental]
    end

    def dependent_attributes
      %w[first_name last_name dob]
    end

    def primary_attributes
      %w[last_name first_name middle_name name_sfx email ssn dob gender]
    end

    def fetch_site_key
      BenefitSponsors::ApplicationController.current_site.site_key
    end

    def census_employee_roster
      @census_employee_roster ||= employer_profile.census_employees.order_name_asc
    end
  end
end
