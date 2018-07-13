module Importers
  module RowSet
    def row_iterator
      @spreadsheet.kind_of?(Roo::Excelx) ? :process_excel_rows : :process_csv_rows
    end

    def import!
      @out_csv << headers
      self.send(row_iterator)
    end

    def process_csv_rows
      (2..@spreadsheet.last_row).each do |idx|
        convert_row(@spreadsheet.row(idx))
      end
    end

    def process_excel_rows
      @sheet = @spreadsheet.sheet(0)
      (2..@sheet.last_row).each do |idx|
        convert_row(@sheet.row(idx))
      end
    end

    def convert_row(row)
      record_attrs = {}
      out_row = []
      row_mapping.each_with_index do |k, idx|
        value = row[idx]
        unless (k == :ignore) || value.blank?
          record_attrs[k] = value.to_s.strip.gsub(/\.0\Z/, "")
        end
      end

      record = create_model(record_attrs)

      import_details = []

      result = false

      errors = String.new

      census_employee_info = Array.new

      begin
        result = record.save

        if result
          if /conversion_employer_results/.match(@out_csv.path)
            organization = find_organization(record.fein)
          end
           # need research here not returning the record after immediate save
          if /conversion_employee_policy_results/.match(@out_csv.path)
            benefit_sponsor = find_organization(record.fein)
            census_employee = find_census_employee(benefit_sponsor.employer_profile, benefit_sponsor.active_benefit_sponsorship, record.subscriber_ssn)
            person = census_employee.first.employee_role.person
            hbx_enroll_ment = find_hbx_enrollments(person)
            census_employee_info << hbx_enroll_ment.hbx_id
            census_employee_info << person.hbx_id
            family_dependents = person.primary_family.family_members.find_all {|family_member| !family_member.is_primary_applicant?}

            family_dependents.each do |family_member|
              census_employee_info.push family_member.person.hbx_id
            end
          end

          if record.warnings.any?
            import_details = ["imported with warnings", JSON.dump(record.warnings.to_hash)]
          else
            import_details = ["imported", ""]
            import_details.push(organization.hbx_id) if organization
          end
        else
          import_details = []
          import_details << ["import failed", JSON.dump(record.errors.to_hash)]
          import_details << ["warnings", JSON.dump(record.warnings.to_hash)] if record.warnings.any?
        end
        @out_csv << (row.map(&:to_s) + import_details + census_employee_info)
      rescue Exception => e
        result = false
        import_details = ["import failed", JSON.dump(e)]
        @out_csv << (row.map(&:to_s) + import_details + census_employee_info)
      end
    end


    def find_organization(fein)
      BenefitSponsors::Organizations::Organization.where(fein: fein).first
    end

    def find_census_employee(employer_profile, sponsorship, subscriber_ssn)
     CensusEmployee.where({
                               benefit_sponsors_employer_profile_id: employer_profile.id,
                               benefit_sponsorship_id: sponsorship.id,
                               encrypted_ssn: CensusMember.encrypt_ssn(subscriber_ssn)
                           })
    end

    def find_hbx_enrollments(person)
      person.primary_family.active_household.hbx_enrollments.select{ |enrollment| enrollment.sponsored_benefit_id.present? && enrollment.benefit_sponsorship_id.present? }.first
    end
  end
end
