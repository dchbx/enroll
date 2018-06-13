module SponsoredBenefits
  module Forms
    class PlanDesignCensusEmployeeImport < SponsoredBenefits::Forms::CensusEmployeeImport

      attr_accessor :proposal

      def proposal=(val)
        @proposal = val
      end

      def benefit_sponsorship
        @proposal.profile.benefit_sponsorships.first
      end

      def employee_klass
        SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee
      end

      def load_imported_census_employees
        # file = 'spec/test_data/spreadsheet_templates/DCHL Employee Census.xlsx'
        @roster = Roo::Spreadsheet.open(@file.tempfile.path)

        @sheet = @roster.sheet(0)
        @last_ee_member = {}
        # To match spreadsheet convention, Roo gem uses 1-based (rather than 0-based) references
        # First three rows are header content
        sheet_header_row = @sheet.row(1)
        @column_header_row = @sheet.row(2)
        # label_header_row  = @sheet.row(3)

        unless header_valid?(sheet_header_row) && column_header_valid?(@column_header_row)
          raise "Unrecognized Employee Census spreadsheet format. Contact #{Settings.site.short_name} for current template."
        end

        census_employees = []
        (4..@sheet.last_row).each_with_index.map do |i, index|
          row = Hash[[@column_header_row, @roster.row(i)].transpose]
          record = parse_row(row)

          if record[:termination_date].present? #termination logic
            census_employee = find_employee(record)
            if census_employee.present?
              @last_ee_member = census_employee
              @last_ee_member_record = record
            end
          else #add or edit census_member logic
            if record[:employee_relationship].nil?
              self.errors.add :base, "Row #{index + 4}: Relationship is required"
              break
            else
              census_employee = add_or_update_census_member(record)
            end
          end

          census_employee ||= nil
          census_employees << census_employee
        end
        census_employees
      end

      def assign_benefit_group(member, benefit_group, plan_year)
        member
      end

        # match by DOB
      def find_employee(record)
        # employees = employee_klass.find_by_benefit_sponsorship(benefit_sponsorship)
        employees = employee_klass.by_benefit_sponsorship(benefit_sponsorship)

        ssn_query = record[:ssn]
        dob_query = record[:dob]
        last_name = record[:last_name]
        first_name = record[:first_name]

        raise ImportErrorValue, "must provide an ssn or first_name/last_name/dob or both" if (ssn_query.blank? && (dob_query.blank? || last_name.blank? || first_name.blank?))

        matches = Array.new
        matches.concat employees.where(encrypted_ssn: encrypt_ssn(ssn_query), dob: dob_query).to_a unless ssn_query.blank?

        if first_name.present? && last_name.present? && dob_query.present?
          first_exp = /^#{first_name}$/i
          last_exp = /^#{last_name}$/i
          matches.concat employees.where(dob: dob_query, last_name: last_exp, first_name: first_exp).to_a
        end

        matches.uniq

        if matches.uniq.size > 1
          raise ImportErrorValue, "found multiple employee records"
        end

        matches.first
      end

    end
  end
end
