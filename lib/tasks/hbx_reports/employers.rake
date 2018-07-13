require 'csv'

namespace :reports do
  namespace :shop do

    desc "All Employers"
    task :employers => :environment do
      include Config::AcaHelper

      date_range = Date.new(2015,10,1)..TimeKeeper.date_of_record

      # census_employees = CensusEmployee.find_all_terminated(date_range: date_range)
      #employer_profiles = EmployerProfile.all
      # orgs = Organization.exists(employer_profile: true).order_by([:legal_name])
      organizations = BenefitSponsors::Organizations::Organization.employer_profiles.order_by([:legal_name])

      field_names  = %w(
          fein
          legal_name
          dba
          employer_aasm_state

          plan_year_start_on
          plan_year_aasm_state

          benefit_package_title
          plan_option_kind
          ref_plan_name
          ref_plan_year
          ref_plan_hios_id
          employee_contribution_pct
          spouse_contribution_pct
          domestic_partner_contribution_pct
          child_under_26_contribution_pct

          staff_name
          staff_phone
          staff_email

          broker_name
          broker_phone
          broker_email
        )

      processed_count = 0

      file_name = fetch_file_format('employers', 'EMPLOYERS')

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        organizations.all.each do |org|
          begin
            er = org.employer_profile
            benefit_application = er.active_benefit_application || er.latest_benefit_application
            next unless benefit_application

            fein                  = er.fein
            legal_name            = er.legal_name
            dba                   = er.dba
            employer_aasm_state   = er.aasm_state

            staff_role = er.staff_roles.first
            if staff_role
              staff_name    = staff_role.full_name
              staff_phone   = staff_role.work_phone || staff_role.mobile_phone
              staff_email   = staff_role.work_email_or_best
            end

            broker_account = er.broker_agency_accounts.first

            if broker_account.present?
              role = broker_account.broker_agency_profile.primary_broker_role
              broker_name   = role.person.full_name
              broker_phone  = role.phone
              broker_email  = role.email.address if role.email
            end

            plan_year_start_on    = benefit_application.start_on
            plan_year_aasm_state  = benefit_application.aasm_state

            benefit_application.benefit_groups.each do |bg|
              benefit_package_title = bg.title

              plan_option_kind      = bg.sponsored_benefits.map(&:product_package_kind).join(',')

              reference_products    = bg.sponsored_benefits.map(&:reference_product)
              ref_plan_name     = reference_products.map(&:title).join(',')
              ref_plan_year     = reference_products.map(&:active_year).join(',')
              ref_plan_hios_id  = reference_products.map(&:hios_id).join(',')

              contribution_levels = bg.sponsored_benefits.map(&:sponsor_contribution).map(&:contribution_levels)
              health_contribution_levels = contribution_levels[0] # No dental for cca

              if health_contribution_levels.size > 2
                employee_contribution_pct = health_contribution_levels.where(display_name: /Employee/i).first.contribution_pct
                spouse_contribution_pct = health_contribution_levels.where(display_name: /Spouse/i).first.contribution_pct
                domestic_partner_contribution_pct = health_contribution_levels.where(display_name: /Domestic Partner/i).first.contribution_pct
                child_under_26_contribution_pct = health_contribution_levels.where(display_name: /Child Under 26/i).first.contribution_pct
              else
                employee_contribution_pct = health_contribution_levels.where(display_name: /Employee Only/i).first.contribution_pct
                spouse_contribution_pct = domestic_partner_contribution_pct = child_under_26_contribution_pct = health_contribution_levels.where(display_name: /Family/i).first.contribution_pct
              end

              csv << field_names.map do |field_name|
                if field_name == "fein"
                  '="' + eval(field_name) + '"'
                else
                  eval("#{field_name}")
                end
              end
              processed_count += 1
            end
          rescue Exception => e
            puts e.message
          end
        end
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} employers output to file: #{file_name}"

      if Rails.env.production?
        pubber = Publishers::Legacy::EmployerReportPublisher.new
        pubber.publish URI.join("file://", file_name)

        pubber = Publishers::LegacyShopReportPublisher.new
        pubber.publish URI.join("file://", file_name)
      end
    end
  end
end
