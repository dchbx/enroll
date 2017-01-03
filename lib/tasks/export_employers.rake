require 'csv'

namespace :employers do
  desc "Export employers to csv."
  # Usage rake employers:export
  task :export => [:environment] do
    orgs = Organization.no_timeout.where("employer_profile" => {"$exists" => true})

    FILE_PATH = Rails.root.join "employer_export.csv"

    def get_primary_office_location(organization)
      organization.office_locations.detect do |office_location|
        office_location.is_primary?
      end
    end
    
    def get_mail_location(organization)
      organization.office_locations.detect do |office_location|
        office_location.address.present? && office_location.address.kind == "mailing"
      end
    end

    def get_broker_agency_account(broker_agency_accounts, plan_year)
      broker_agency_account = broker_agency_accounts.detect do |broker_agency_account|
        next if broker_agency_account.end_on.nil?
        (plan_year.start_on >= broker_agency_account.start_on) && (plan_year.end_on <= broker_agency_account.end_on)
      end

      broker_agency_account = broker_agency_accounts.first if broker_agency_account.nil?
      broker_agency_account
    end

    CSV.open(FILE_PATH, "w") do |csv|

      headers = %w(employer.legal_name employer.dba employer.fein employer.hbx_id employer.entity_kind employer.sic_code employer_profile.profile_source employer.status ga_fein ga_agency_name ga_start_on
                                office_location.is_primary office_location.address.address_1 office_location.address.address_2
                                office_location.address.city office_location.address.state office_location.address.zip mailing_location.address_1 mailing_location.address_2 mailing_location.city mailing_location.state mailing_location.zip
                                office_location.phone.full_phone_number staff.name staff.phone staff.email
                                employee offered spouce offered domestic_partner offered child_under_26 offered child_26_and_over
                                offered benefit_group.title benefit_group.plan_option_kind
                                benefit_group.carrier_for_elected_plan benefit_group.metal_level_for_elected_plan benefit_group.single_plan_type?
                                benefit_group.reference_plan.name benefit_group.effective_on_kind benefit_group.effective_on_offset
                                plan_year.start_on plan_year.end_on plan_year.open_enrollment_start_on plan_year.open_enrollment_end_on
                                plan_year.fte_count plan_year.pte_count plan_year.msp_count plan_year.status plan_year.publish_date broker_agency_account.corporate_npn broker_agency_account.legal_name
                                broker.name broker.npn broker.assigned_on)
      csv << headers

      orgs.all.each do |org| 
        begin
          employer = org.employer_profile

          puts employer.legal_name + ": no general agency profile" if employer.general_agency_profile.nil?
          gap_fein = !employer.general_agency_profile.nil? ? employer.general_agency_profile.fein : ""
          gap_legal_name = !employer.general_agency_profile.nil? ? employer.general_agency_profile.legal_name : ""
          gap_active_start_on = !employer.active_general_agency_account.nil? ? employer.active_general_agency_account.start_on : "" 

          employer_attributes = [employer.legal_name, employer.dba, employer.fein, employer.hbx_id, employer.entity_kind, employer.sic_code, employer.profile_source, employer.aasm_state, gap_fein, gap_legal_name, gap_active_start_on]
          office_location = get_primary_office_location(employer.organization)
          employer_attributes += [office_location.is_primary, office_location.address.address_1, office_location.address.address_2, office_location.address.city,
                                  office_location.address.state, office_location.address.zip]
          mailing_location = get_mail_location(employer.organization)
          
          if mailing_location.present?
            employer_attributes += [mailing_location.address.address_1, mailing_location.address.address_2, mailing_location.address.city, mailing_location.address.state, mailing_location.address.zip]
          else
            employer_attributes += ["", "", "", "", ""]
          end
          if office_location.phone.present?
            employer_attributes += [office_location.phone.full_phone_number]
          else
            employer_attributes += [""]
          end

          if employer.staff_roles.size > 0
            staff_role = employer.staff_roles.first
            staff_name = staff_role.full_name
            employer_attributes += [staff_name]

            employer_attributes += [staff_role.work_phone_or_best || 'Not provided']

            employer_attributes += [staff_role.work_email_or_best || "Not provided"]
   
          else
            employer_attributes += ["", "", ""]
          end
          
            employer_attributes += []

          employer.plan_years.each_with_index do |plan_year, i|

            plan_year.benefit_groups.each do |benefit_group|
              #benefit_group.relationship_benefits.each do |relationship_benefit|
                row = []

                puts employer.legal_name + " - Plan Year " + plan_year.id.to_s + " : no workflow state transitions" if plan_year.workflow_state_transitions.size == 0
                plan_year_transition_at = plan_year.workflow_state_transitions.size > 0 ? plan_year.workflow_state_transitions.order(transition_at: :desc).first.transition_at : ""

                begin
                  row += [benefit_group.relationship_benefits[0].premium_pct.try(:to_f).try(:round), benefit_group.relationship_benefits[0].offered, benefit_group.relationship_benefits[1].premium_pct.try(:to_f).try(:round), benefit_group.relationship_benefits[1].offered, benefit_group.relationship_benefits[2].premium_pct.try(:to_f).try(:round), benefit_group.relationship_benefits[2].offered, benefit_group.relationship_benefits[3].premium_pct.try(:to_f).try(:round), benefit_group.relationship_benefits[3].offered, benefit_group.relationship_benefits[4].premium_pct.try(:to_f).try(:round), benefit_group.relationship_benefits[4].offered]

                  row += [benefit_group.title, benefit_group.plan_option_kind,
                          (benefit_group.plan_option_kind == "single_carrier" ? CarrierProfile.find(benefit_group.reference_plan.carrier_profile_id).abbrev : ''),
                          (benefit_group.plan_option_kind == 'metal_level' ? benefit_group.reference_plan.metal_level : ''), 
                          (benefit_group.plan_option_kind == 'single_plan'),
                          benefit_group.reference_plan.name, benefit_group.effective_on_kind, benefit_group.effective_on_offset]
                  row += [plan_year.start_on, plan_year.end_on, plan_year.open_enrollment_start_on, plan_year.open_enrollment_end_on,
                          plan_year.fte_count, plan_year.pte_count, plan_year.msp_count, plan_year.aasm_state, plan_year_transition_at]

                  broker_agency_account = get_broker_agency_account(employer.broker_agency_accounts, plan_year)
                  if broker_agency_account.present?
                    row += [broker_agency_account.broker_agency_profile.corporate_npn, broker_agency_account.broker_agency_profile.legal_name]
                    if broker_agency_account.broker_agency_profile.primary_broker_role.present?
                      row += [broker_agency_account.broker_agency_profile.primary_broker_role.person.first_name + " " + broker_agency_account.broker_agency_profile.primary_broker_role.person.last_name]
                      row += [broker_agency_account.broker_agency_profile.primary_broker_role.npn, broker_agency_account.start_on]
                    else
                      row += ["",""]
                    end
                  else
                    row += ["", "", ""]
                  end
                rescue Exception => e
                  puts "ERROR: #{employer.legal_name} " + e.message
                  next
                end
                  csv << employer_attributes + row
                  #csv << ['','','','','','','','','','','','','','','','', '', '', '','','','','', '', '', ''] + row if i >0 
                #end
            end
          end
          csv << employer_attributes if employer.plan_years.empty?
        rescue Exception => e
          puts "ERROR: #{employer.legal_name} " + e.message
        end
      end

    end

    puts "Output written to #{FILE_PATH}"

  end
end
