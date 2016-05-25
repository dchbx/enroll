require 'csv'

namespace :employers do
  desc "Export employers to csv."
  # Usage rake employers:export
  task :export => [:environment] do
    employers = Organization.where("employer_profile" => {"$exists" => true}).map(&:employer_profile)

    FILE_PATH = Rails.root.join "employer_export.csv"

    def get_primary_office_location(organization)
      organization.office_locations.detect do |office_location|
        office_location.is_primary?
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

      headers = %w(employer.legal_name employer.dba employer.fein employer.hbx_id employer.entity_kind employer.sic_code
                                office_location.is_primary office_location.address.address_1 office_location.address.address_2
                                office_location.address.city office_location.address.state office_location.address.zip
                                office_location.phone.full_phone_number staff.name staff.phone staff.email
                                relationship_benefit.relationship relationship_benefit.premium_pct
                                relationship_benefit.offered benefit_group.title, benefit_group.plan_option_kind
                                benefit_group.carrier_for_elected_plan benefit_group.metal_level_for_elected_plan benefit_group.single_plan_type?
                                benefit_group.reference_plan.name benefit_group.effective_on_kind benefit_group.effective_on_offset
                                plan_year.start_on plan_year.end_on plan_year.open_enrollment_start_on plan_year.open_enrollment_end_on
                                plan_year.fte_count plan_year.pte_count plan_year.msp_count broker_agency_account.corporate_npn broker_agency_account.legal_name
                                broker.name)
      csv << headers

      employers.each do |employer|
        begin
          employer_attributes = []
          employer_attributes += [employer.legal_name, employer.dba, employer.fein, employer.hbx_id, employer.entity_kind, employer.sic_code]
          office_location = get_primary_office_location(employer.organization)

          #6780 Add unless office_location.nil? in case Organization has no office_locations.
          employer_attributes += [office_location.is_primary, office_location.address.address_1, office_location.address.address_2, office_location.address.city,
                                  office_location.address.state, office_location.address.zip] unless office_location.nil?

          #6780. Add try in case office_location is nil
          if office_location.try(:phone).present?
            employer_attributes += [office_location.phone.full_phone_number]
          else
            employer_attributes += [""]
          end

          puts "WARNING: #{employer.legal_name} has no office locations" if office_location.nil?

          if employer.staff_roles.size > 0
            staff_role = employer.staff_roles.first
            staff_name = staff_role.full_name
            employer_attributes += [staff_name]

            if staff_role.phones.present? && staff_role.phones.where(kind: "work").size > 0
              employer_attributes += [staff_role.phones.where(kind: "work").first.full_phone_number]
            else
              employer_attributes += [""]
            end

            if staff_role.emails.present? && staff_role.emails.where(kind: "work").size > 0
              employer_attributes += [staff_role.emails.where(kind: "work").first.address]
            else
              employer_attributes += [""]
            end
          else
            employer_attributes += ["", "", ""]
          end

          employer.plan_years.each do |plan_year|
            plan_year.benefit_groups.each do |benefit_group|
              benefit_group.relationship_benefits.each do |relationship_benefit|
                row = []

                begin
                  row += [relationship_benefit.relationship, relationship_benefit.premium_pct,
                          relationship_benefit.offered]
                  row += [benefit_group.title, benefit_group.plan_option_kind, benefit_group.carrier_for_elected_plan,
                          benefit_group.metal_level_for_elected_plan, (benefit_group.single_plan_type? ? benefit_group.elected_plans_by_option_kind.name : ""),
                          benefit_group.reference_plan.name, benefit_group.effective_on_kind, benefit_group.effective_on_offset]
                  row += [plan_year.start_on, plan_year.end_on, plan_year.open_enrollment_start_on, plan_year.open_enrollment_end_on,
                          plan_year.fte_count, plan_year.pte_count, plan_year.msp_count]

                  broker_agency_account = get_broker_agency_account(employer.broker_agency_accounts, plan_year)
                  if broker_agency_account.present?
                    row += [broker_agency_account.broker_agency_profile.primary_broker_role.npn, broker_agency_account.broker_agency_profile.legal_name]
                    if broker_agency_account.broker_agency_profile.primary_broker_role.present?
                      row += [broker_agency_account.broker_agency_profile.primary_broker_role.person.first_name + " " + broker_agency_account.broker_agency_profile.primary_broker_role.person.last_name]
                    else
                      row += [""]
                    end
                  else
                    row += ["", ""]
                  end
                rescue Exception => e
                  puts "ERROR: #{employer.legal_name} " + e.message
                  next
                end

                csv << employer_attributes + row
              end
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
