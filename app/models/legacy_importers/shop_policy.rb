module LegacyImporters
  class ShopPolicy
    attr_reader :errors

    def initialize(data_row)
      @data_hash = data_row
      @errors = ActiveModel::Errors.new(self)
    end

    def save
      basic_props = extract_policy_properties
      ret_val = true
      sc = ShortCircuit.new(:missing_object) do |mo_message|
        @errors.add(:base, mo_message)
        false
      end
      sc.and_then do |d_hash|
        @person = locate_head_of_family(d_hash)
        @family = locate_family(@person)
        @plan = find_plan(d_hash)
        @employer = find_employer(d_hash)
        @applicant_lookup = construct_applicant_lookup(@family)
        @household = @family.households.first
        @coverage_houselhold = @household.coverage_households.first
        @plan_year = @employer.plan_years.first
        @benefit_group = @plan_year.benefit_groups.first
        @census_record = find_roster_entry(@employer, @person, @benefit_group)
        @member_properties = construct_member_properties(d_hash, @applicant_lookup, @person)
        props_hash = enrollment_properties_hash(@benefit_group, @census_record, @plan, @coverage_household, @member_properties)
        enrollment = @household.hbx_enrollments.create!(props_hash)
        enrollment_to_update = HbxEnrollment.find(enrollment.id)
        enrollment_to_update.select_coverage
        enrollment_to_update.household.save!
        true
      end
      sc.call(@data_hash)
    end

    def enrollment_properties_hash(bg, ce, plan, ch, member_props)
      e_on = member_props.map { |mp| mp[:coverage_start_on] }.min
      {
        :hbx_id => @hbx_id,
        :hbx_enrollment_members_attributes => member_props,
        :kind => "employer_sponsored",
        :benefit_group_id => bg.id,
        :benefit_group_assignment_id => ce.active_benefit_group_assignment.id,
        :plan_id => plan.id,
        :effective_on => e_on
      }
    end

    def construct_member_properties(data, app_lookup, sub)
      data["enrollees"].map do |en|
        m_id = en["hbx_id"]
        is_sub = (m_id == sub.hbx_id)
        prop_hash = {
          :applicant_id => app_lookup[m_id].id,
          :premium_amount => en["premium_amount"],
          :is_subscriber => is_sub,
          :coverage_start_on => Date.strptime(en["coverage_start"], "%Y%m%d"),
          :eligibility_date => Date.strptime(en["coverage_start"], "%Y%m%d")
        }
        if !prop_hash["coverage_end"].blank?
          prop_hash[:coverage_end_on] = Date.strptime(en["coverage_end"], "%Y%m%d")
        end
        prop_hash
      end
    end

    def find_roster_entry(employer, person, bg)
      first_pass = CensusEmployee.by_benefit_group_ids([bg.id]).by_ssn(person.ssn).first
      return first_pass if !first_pass.nil?
      CensusEmployee.roster_import_fallback_match(person.first_name, person.last_name, person.dob, bg.id).first.tap do |er|
        throw :missing_object, "Could not match employee for FEIN #{employer.fein}, SSN #{person.ssn}" if er.nil?
        if !person.ssn.blank?
          er.update_attributes!(:ssn => person.ssn, :aasm_state => "eligible")
        end
      end
    end

    def construct_applicant_lookup(family)
      applicant_lookup = {}
      family.family_members.each do |app|
        applicant_lookup[app.person.hbx_id] = app
      end
      applicant_lookup
    end

    def extract_policy_properties
      @hbx_id = @data_hash["hbx_id"]
      @employer_contribution = @data_hash["employer_contribution"]
      @premium_total = @data_hash["pre_amt_tot"]
      @tot_res_amount = @data_hash["tot_res_amount"]
    end

    def locate_family(person)
      Family.find_all_by_primary_applicant(person).first.tap do |fam|
        throw :missing_object, "Could not find family for subscriber with hbx_id: #{person.hbx_id}" if fam.nil?
      end
    end

    def locate_head_of_family(data)
      Person.where(:hbx_id => data["subscriber_id"]).first.tap do |person|
        throw :missing_object, "Could not find subscriber with hbx_id: #{data["subscriber_id"]}" if person.nil?
      end
    end

    def find_plan(data)
      @hios = data["plan"]["hios_id"]
      @active_year = data["plan"]["active_year"]
      Plan.where({hios_id: @hios, active_year: @active_year.to_i}).first
    end

    def find_employer(data)
      @employer_fein = data["employer_fein"]
      org = BenefitSponsors::Organizations::Organization.where(fein: @employer_fein).first
      throw :missing_object, "No organization with fein: #{@employer_fein}" if org.nil?
      org.employer_profile.tap do |ep|
        throw :missing_object, "No employer_profile for organization with fein: #{@employer_fein}" if ep.nil?
      end
    end
  end
end
