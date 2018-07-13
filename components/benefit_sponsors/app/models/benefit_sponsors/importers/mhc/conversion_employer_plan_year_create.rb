module BenefitSponsors
module Importers::Mhc
  class ConversionEmployerPlanYearCreate < ConversionEmployerPlanYear

    def map_plan_year(employer_profile)
      issuer_profile   = find_carrier

      benefit_sponsorship = employer_profile.organization.benefit_sponsorships.first
      benefit_application = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(benefit_sponsorship, fetch_application_params)

      # return false if service_areas_missing?(benefit_application)
      # return false if rating_area_missing?(benefit_application)
      # benefit_sponsorship.service_areas = benefit_application.recorded_service_areas
      # benefit_sponsorship.rating_area = benefit_application.recorded_rating_area
      
      catalog_date = mid_year_conversion ? orginal_plan_year_begin_date : default_plan_year_start
      benefit_application.recorded_service_areas = benefit_sponsorship.service_areas_on(catalog_date)
      benefit_application.recorded_rating_area = benefit_sponsorship.rating_area_on(catalog_date)

      benefit_application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.recorded_service_areas, catalog_date)

     BenefitSponsors::Importers::BenefitPackageImporter.call(benefit_application, benefit_package_attributes)

      benefit_application
    end

    def fetch_application_params
      service = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new

      plan_year_begin = default_plan_year_start
      if mid_year_conversion
        if orginal_plan_year_begin_date > default_plan_year_start
          plan_year_begin = orginal_plan_year_begin_date
        end
      end

      formed_params = service.default_dates_for_coverage_starting_on(plan_year_begin)
      
      if mid_year_conversion
        effective_period = formed_params[:effective_period]
        formed_params[:effective_period] = effective_period.min..plan_year_end
      end

      formed_params.merge({ 
        fte_count: enrolled_employee_count, 
        aasm_state: (mid_year_conversion ? :active : :imported)
      })
    end

    def benefit_package_attributes
      {
        title: 'Standard',
        description: 'Standard package',
        is_active: true,
        effective_on_kind: new_coverage_policy_value.kind,
        effective_on_offset: new_coverage_policy_value.offset,
        is_default: true,
        plan_option_kind: plan_selection,
        reference_plan_hios_id: single_plan_hios_id,
        composite_tier_contributions: tier_contribution_values
      }
    end

    def tier_contribution_values
      contribution_level_names = [
        "employee_only",
        "employee_and_spouse",
        "employee_and_one_or_more_dependents",
        "family"
      ]
      contribution_level_names.inject([]) do |contributions, sponsor_level_name|
        contributions << {
          relationship: sponsor_level_name,
          offered: tier_offered?(sponsor_level_name),
          premium_pct: eval("#{sponsor_level_name}_rt_contribution"),
          estimated_tier_premium: eval("#{sponsor_level_name}_rt_premium")
        }
      end
    end

    def tier_offered?(preference)
      return true if preference == "employee_only"
      (preference.present?) ? true : false
    end

    def plan_year_exists?(sponsorship)
      if sponsorship.benefit_applications.present?
        errors.add(:application_exists, "Benefit Application already created!!")
        return true
      end
      false
    end

    def rating_area_missing?(sponsorship)
      if sponsorship.rating_area.blank?
        errors.add(:rating_area, "Benefit Sponsorship rating area blank")
        return true
      end
      false
    end

    def service_areas_missing?(sponsorship)
      if sponsorship.service_areas.blank?
        errors.add(:service_areas, "Benefit Sponsorship service areas blank")
        return true
      end
      false
    end

    def save
      return false unless valid?
      employer_profile = find_employer
      sponsorship = employer_profile.organization.benefit_sponsorships[0]
      return false if plan_year_exists?(sponsorship)

      record = map_plan_year(employer_profile)
      if save_result = record.save
        catalog = record.benefit_sponsor_catalog
        catalog.benefit_application = record
        catalog.save
      end
      
      propagate_errors(record)

      if save_result
        benefit_sponsorship = record.benefit_sponsorship
        benefit_sponsorship.update(effective_begin_on: record.start_on, aasm_state: :active)
        benefit_sponsorship.workflow_state_transitions.create({
           from_state: 'applicant',
           to_state: 'active'
          })

        map_employees_to_benefit_groups(benefit_sponsorship, record)
      end
      return save_result
    end
  end
end
end
