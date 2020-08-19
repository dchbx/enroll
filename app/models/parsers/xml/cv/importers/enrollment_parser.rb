module Parsers::Xml::Cv::Importers
  class EnrollmentParser
    include Parsers::Xml::Cv::Importers::Base
    attr_reader :policy, :enrollment

    def initialize(input_xml)
      @policy = Openhbx::Cv2::Policy.parse(input_xml, single: true)
      @enrollment = @policy.policy_enrollment
    end

    def get_enrollment_object
      kind = enrollment.individual_market.present? ? 'individual' : 'employer_sponsored'
      individual_market = enrollment.individual_market
      elected_aptc_pct = individual_market.present? ? individual_market.elected_aptc_percent.to_f : 0
      applied_aptc_amount = individual_market.present? ? individual_market.applied_aptc_amount.to_f : 0
      if e_plan = enrollment.plan
        metal_level = e_plan.metal_level.strip.split("#").last
        coverage_type = e_plan.coverage_type.strip.split("#").last
        plan = Plan.new(
          id: e_plan.id,
          hios_id: e_plan.id,
          name: e_plan.name,
          active_year: e_plan.active_year,
          metal_level: metal_level,
          coverage_kind: coverage_type,
          ehb: e_plan.ehb_percent.to_f,
          #plan_type: ,
        )
      end
      hbx_enrollment_members = []
      policy.enrollees.each do |enrollee|
        hbx_enrollment_members << HbxEnrollmentMember.new(
          applicant_id: enrollee.member.id,
          is_subscriber: enrollee.is_subscriber == 'true',
          coverage_start_on: enrollee.benefit.begin_date,
          coverage_end_on: enrollee.benefit.end_date,
          premium_amount: enrollee.benefit.premium_amount,
          #applied_aptc_amount: , # can not find it in xml
        )
      end
      coverage_type = enrollment.plan.coverage_type.strip.split('#').last rescue ''
      enrollee = policy.enrollees.detect {|enrollee| enrollee.is_subscriber == 'true'}
      effective_on = enrollee.benefit.begin_date rescue ''
      terminated_on = enrollee.benefit.end_date rescue ''
      HbxEnrollment.new(
        hbx_id: policy.id,
        kind: kind,
        elected_aptc_pct: elected_aptc_pct,
        applied_aptc_amount: applied_aptc_amount,
        plan: plan,
        carrier_profile_id: enrollment.plan.try(:carrier).try(:id),
        #writing_agent_id: broker_link.id,
        #terminated_on: ,
        coverage_kind: coverage_type,
        #enrollment_kind: ,
        #count_of_members: policy.enrollees.length,
        hbx_enrollment_members: hbx_enrollment_members,
        household: get_household_by_policy_xml(policy),
        effective_on: effective_on,
        terminated_on: terminated_on,
        employee_role: get_employee_role_by_shop_market_xml(enrollment.shop_market),
        broker: get_broker_role_by_broker_xml(policy.broker_link),
      )
    end

    def get_broker_role_object
      return nil if policy && policy.broker_link.blank?
      broker = policy.broker_link
      first_name = broker.name.split(' ').first rescue ''
      last_name = broker.name.split(' ').last rescue ''

      BrokerRole.new(
        npn: broker.id,
        person: Person.new(
          first_name: first_name,
          last_name: last_name,
        )
      )
    end

    def get_broker_role_by_broker_xml(broker)
      return nil if broker.blank?
      first_name = broker.name.split(' ').first rescue ''
      last_name = broker.name.split(' ').last rescue ''

      BrokerRole.new(
        npn: broker.id,
        person: Person.new(
          first_name: first_name,
          last_name: last_name,
        )
      )
    end

    def get_employee_role_by_shop_market_xml(shop_market)
      return nil if shop_market.blank?
      employer = shop_market.employer_link
      fein = employer.id.strip.split('#').last rescue ''
      org = Organization.new(
        fein: fein,
        legal_name: employer.try(:name)
      )
      
      EmployeeRole.new(
        employer_profile: EmployerProfile.new(organization: org)
      )
    end

    def get_household_by_policy_xml(policy)
      family_members = []
      policy.enrollees.each do |enrollee|
        member = enrollee.member
        family_members << FamilyMember.new(
          id: member.id,
          is_primary_applicant: enrollee.is_subscriber == 'true',
          is_coverage_applicant: member.is_coverage_applicant == 'true',
          person: get_person_object_by_enrollee_member_xml(member),
        )
      end
      family = Family.new(family_members: family_members)
      Household.new(family: family)
    end

    def get_person_object_by_enrollee_member_xml(member)
      person = member.person
      person_demographics = member.person_demographics
      person_relationships = member.person_relationships

      get_person_object_by(person, person_demographics, person_relationships, member.primary_family_id)
    end
  end
end
