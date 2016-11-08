require 'csv'

namespace :reports do
  namespace :shop do

    desc "All Employers"
    task :employers => :environment do

      date_range = Date.new(2015,10,1)..TimeKeeper.date_of_record

      # census_employees = CensusEmployee.find_all_terminated(date_range: date_range)
      #employer_profiles = EmployerProfile.all
      orgs = Organization.exists(employer_profile: true).order_by([:legal_name])

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
      file_name = "#{Rails.root}/public/employers.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        orgs.all.each do |org|
          er = org.employer_profile
          plan_year = er.active_plan_year || er.latest_plan_year
          next unless plan_year

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

          if er.broker_agency_profile
            broker_role = er.broker_agency_profile.primary_broker_role
            if broker_role
              broker_name   = broker_role.person.full_name
              broker_phone  = broker_role.phone
              broker_email  = broker_role.email.address if broker_role.email
            end
          end

          plan_year_start_on    = plan_year.start_on
          plan_year_aasm_state  = plan_year.aasm_state
          
          plan_year.benefit_groups.each do |bg|
            benefit_package_title = bg.title
            plan_option_kind      = bg.plan_option_kind

            reference_plan    = bg.reference_plan
            ref_plan_name     = reference_plan.name
            ref_plan_year     = reference_plan.active_year
            ref_plan_hios_id  = reference_plan.hios_id

            if bg.relationship_benefits.detect { |rb| rb.relationship == "employee"}.try(:premium_pct)
              employee_contribution_pct = bg.relationship_benefits.detect { |rb| rb.relationship == "employee"}.premium_pct
            else
              employee_contribution_pct = 0
            end

            if bg.relationship_benefits.detect { |rb| rb.relationship == "spouse"}.try(:premium_pct)
              spouse_contribution_pct = bg.relationship_benefits.detect { |rb| rb.relationship == "spouse"}.premium_pct
            else
              spouse_contribution_pct = 0
            end

            if bg.relationship_benefits.detect { |rb| rb.relationship == "domestic_partner"}.try(:premium_pct)
              domestic_partner_contribution_pct = bg.relationship_benefits.detect { |rb| rb.relationship == "domestic_partner"}.premium_pct
            else
              domestic_partner_contribution_pct = 0
            end

            if bg.relationship_benefits.detect { |rb| rb.relationship == "child_under_26"}.try(:premium_pct)
              child_under_26_contribution_pct = bg.relationship_benefits.detect { |rb| rb.relationship == "child_under_26"}.premium_pct
            else
              child_under_26_contribution_pct = 0
            end

            # spouse_contribution_pct           = bg.relationship_benefits.detect { |rb| rb.relationship == "spouse"}.premium_pct
            # domestic_partner_contribution_pct = bg.relationship_benefits.detect { |rb| rb.relationship == "domestic_partner"}.premium_pct
            # child_under_26_contribution_pct   = bg.relationship_benefits.detect { |rb| rb.relationship == "child_under_26"}.premium_pct


            # if er.binder_paid? ||er.enrolled? || er.suspended?
            # end

            csv << field_names.map do |field_name|
              if field_name == "fein"
                '="' + eval(field_name) + '"'
              else
                eval("#{field_name}")
              end
            end
            processed_count += 1
          end
        end
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} employers output to file: #{file_name}"
    end
  end
end
