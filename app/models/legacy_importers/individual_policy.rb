# frozen_string_literal: true

module LegacyImporters
  class IndividualPolicy
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
        check_existing_enrollment(d_hash)
        @person = locate_head_of_family(d_hash)
        @family = locate_family(@person)
        @plan = find_plan(d_hash)
        @applicant_lookup = construct_applicant_lookup(@family)
        @household = @family.households.first
        @coverage_household = @household.coverage_households.first
        @member_properties = construct_member_properties(d_hash, @applicant_lookup, @person)
        @consumer_role = create_consumer_role(@person)
        props_hash = enrollment_properties_hash(@consumer_role, @plan, @coverage_household, @member_properties)
        enrollment = @household.hbx_enrollments.create!(props_hash)
        enrollment_to_update = HbxEnrollment.find(enrollment.id)
        enrollment_to_update.select_coverage
        enrollment_to_update.household.save!
        true
      end
      sc.call(@data_hash)
    end

    def check_existing_enrollment(dhash)
      p_id = dhash["hbx_id"]
      pol = HbxEnrollment.by_hbx_id(p_id).first
      throw :missing_object, "Policy already exists with hbx_id: #{p_id}" if pol
    end

    def create_consumer_role(person)
      cr = person.consumer_role
      if cr.nil?
        cr = ConsumerRole.create!(
          :person => person,
          :is_applicant => true,
          :lawful_presence_determination => LawfulPresenceDetermination.new(
            :vlp_authority => "curam",
            :vlp_verified_at => Time.now,
            :aasm_state => "verification_successful"
          ),
          :aasm_state => "fully_verified",
          :is_state_resident => true
        )
      end
      cr
    end

    def enrollment_properties_hash(cr, plan, _ch, member_props)
      e_on = member_props.map { |mp| mp[:coverage_start_on] }.min
      {
        :applied_aptc_amount => @aptc,
        :consumer_role_id => cr.id,
        :hbx_id => @hbx_id,
        :hbx_enrollment_members_attributes => member_props,
        :kind => "individual",
        :plan_id => plan.id,
        :effective_on => e_on
      }
    end

    def construct_member_properties(data, app_lookup, sub)
      data["enrollees"].each do |en|
        m_id = en["hbx_id"]
        applicant = app_lookup[m_id]
        if applicant.nil?
          throw :missing_object, "Could not find member with hbx_id: #{m_id}" if applicant.nil?
        end
      end
      data["enrollees"].map do |en|
        m_id = en["hbx_id"]
        is_sub = (m_id == sub.hbx_id)
        create_consumer_role(app_lookup[m_id].person) unless is_sub
        prop_hash = {
          :applicant_id => app_lookup[m_id].id,
          :premium_amount => en["premium_amount"],
          :is_subscriber => is_sub,
          :coverage_start_on => Date.strptime(en["coverage_start"], "%Y%m%d"),
          :eligibility_date => Date.strptime(en["coverage_start"], "%Y%m%d")
        }
        prop_hash[:coverage_end_on] = Date.strptime(en["coverage_end"], "%Y%m%d") unless prop_hash["coverage_end"].blank?
        prop_hash
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
      @aptc = @data_hash["applied_aptc"]
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
        throw :missing_object, "Could not find subscriber with hbx_id: #{data['subscriber_id']}" if person.nil?
      end
    end

    def find_plan(data)
      @hios = data["plan"]["hios_id"]
      @active_year = data["plan"]["active_year"]
      Plan.where({hios_id: @hios, active_year: @active_year.to_i}).first.tap do |pl|
        throw :missing_object, "Could not find plan with hios_id #{@hios}, active year #{@active_year}" if pl.nil?
      end
    end
  end
end
