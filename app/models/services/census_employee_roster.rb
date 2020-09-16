# frozen_string_literal: true

module Services
  class CensusEmployeeRoster
    include ActionView::Helpers::NumberHelper

    attr_reader :employer_profile, :site_key, :feature
    attr_accessor :headers, :type_of_action, :dep_count

    def initialize(employer_profile, options = {})
      @employer_profile = employer_profile
      @site_key = fetch_site_key
      @dep_count = dependent_count
      @type_of_action = options[:action]
      @feature = options[:feature]
      @headers = config_based_headers
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << (["#{Settings.site.long_name} Employee Census Template"] + Array.new(6) + [TimeKeeper.date_of_record] + Array.new(5) + ['1.1'])
        csv << headers

        @bqt_array = Array.new(3) if is_bqt?
        @total_employer_contribution ||= total_premium(benefit_pkgs) if site_key == :dc

        census_employee_roster.each do |census_employee|
          personal_details = personal_headers(census_employee)
          employee_details = employeement_headers(census_employee)
          benefit_group_details = benefit_group_assignment_details(census_employee)
          address_details = primary_location_details(census_employee)
          append_config_data = ['', 'employee'] + personal_details + employee_details + benefit_group_details + address_details

          if site_key == :dc
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
      return @bqt_array if @bqt_array.present?

      bga = []
      active_assignment = census_employee.active_benefit_group_assignment
      if active_assignment
        health_enrollment = pull_enrollment_state_by_kind(active_assignment, 'health')
        dental_enrollment = pull_enrollment_state_by_kind(active_assignment, 'dental')
        title = active_assignment.benefit_package.title if active_assignment.benefit_package
        py_start_on = active_assignment.benefit_application.start_on if active_assignment.benefit_application
        bga.push(
            title,
            "dental: #{dental_enrollment}  health: #{health_enrollment}",
            py_start_on
        )
      else
        bga += Array.new(3)
      end
      bga
    end

    def pull_enrollment_state_by_kind(active_bga, coverage_kind)
      enrollment = active_bga.hbx_enrollments.detect {|enrollment| enrollment.coverage_kind == coverage_kind}
      enrollment.aasm_state.humanize.downcase if enrollment
    end

    def total_premium(benefit_packages)
      if is_bqt?
        bqt_estimated_premium
      elsif benefit_packages && is_employer?
        employer_estimated_premium(benefit_packages)
      else
        Array.new(2)
      end
    end

    def employer_estimated_premium(benefit_packages)
      premiums = []
      estimator = ::BenefitSponsors::Services::SponsoredBenefitCostEstimationService.new

      @health_premium = 0
      @dental_premium = 0

      benefit_packages.each do |pkg|
        pkg.sponsored_benefits.each do |sponsored_benefit|
          #As per the current requirement, total premium for the employer is calculated and recorded in the excel.
          cost_hash = estimator.calculate_estimates_for_benefit_display(sponsored_benefit)
          @health_premium += (cost_hash ? cost_hash[:estimated_sponsor_exposure] : 0) if sponsored_benefit.health?
          @dental_premium += (cost_hash ? cost_hash[:estimated_sponsor_exposure] : 0) unless sponsored_benefit.health?
        end
      end

      premiums.push(number_to_currency(@health_premium), number_to_currency(@dental_premium))

      # handles Only health/dental present or none
      premiums += Array.new(2 - premiums.count)
    end

    def bqt_estimated_premium
      premiums = []

      sponsor_ship = employer_profile.benefit_sponsorships.first
      return Array.new(2) if sponsor_ship.nil?

      benefit_group = sponsor_ship.benefit_applications.first.benefit_groups.first
      return Array.new(2) if benefit_group.nil?

      sponsored_service = ::SponsoredBenefits::Services::PlanCostService.new({benefit_group: benefit_group})
      health_plan = benefit_group.reference_plan
      dental_plan = benefit_group.dental_reference_plan

      #As per the current requirement, total premium for the employer is calculated and recorded in the excel.
      er_health_contribution_amount = sponsored_service.monthly_employer_contribution_amount(health_plan)
      er_dental_contribution_amount = sponsored_service.monthly_employer_contribution_amount(dental_plan) if dental_plan.present?
      premiums.push(number_to_currency(er_health_contribution_amount), number_to_currency(er_dental_contribution_amount))

      # handles Only health/dental present or none
      premiums += Array.new(2 - premiums.count)
    end

    private

    def is_bqt?
      feature == 'bqt'
    end

    def is_employer?
      feature == 'employer'
    end

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
      %w[last_name first_name middle_name name_sfx email_address ssn dob gender]
    end

    def fetch_site_key
      BenefitSponsors::ApplicationController.current_site.site_key
    end

    def census_employee_roster
      @census_employee_roster ||= employer_profile.census_employees.order_name_asc
    end

    def current_application
      employer_profile.current_benefit_application
    end

    def benefit_pkgs
      return nil if is_bqt?
      current_application.benefit_packages
    end
  end
end
