module Parsers::Xml::Cv::Importers
  class FamilyParser
    include Parsers::Xml::Cv::Importers::Base
    attr_reader :family, :id, :e_case_id, :primary_family_member_id, :family_members, :households, :irs_groups

    def initialize(input_xml)
      @family = Openhbx::Cv2::Family.parse(input_xml, single: true)
      @id = family.id
      @e_case_id = family.e_case_id
      @primary_family_member_id = family.primary_family_member_id
      @family_members = family.family_members
      @households = family.households
      @irs_groups = family.irs_groups
    end

    def get_family_object
      family_member_objects = []
      if family_members
        family_members.each do |fm|
          is_primary_applicant = primary_family_member_id == fm.id || fm.is_primary_applicant.to_s == 'true'
          family_member_objects << FamilyMember.new(
            id: fm.id,
            # hbx_id: fm.id,
            former_family_id: fm.primary_family_id,
            is_primary_applicant: is_primary_applicant, # did not see the real xml  
            is_coverage_applicant: fm.is_coverage_applicant.to_s == 'true', # need to confirm the case sensetive
            person: get_person_object_by_family_member_xml(fm),
          )
        end
        generate_person_relationships_for_primary_applicant(family_member_objects)
      end
      household_objects = []
      if households
        households.each do |h|
          household_objects << Household.new(
            id: h.id,
            irs_group_id: h.irs_group_id,
            effective_starting_on: h.start_date,
            effective_ending_on: h.end_date,
            coverage_households: get_coverage_households_by_household_xml(h),
            tax_households: get_tax_households_by_household_xml(h),
          )
        end
      end
      irs_group_objects = []
      if irs_groups
        irs_groups.each do |irs|
          irs_group_objects << IrsGroup.new(
            hbx_assigned_id: irs.id,
            effective_starting_on: irs.effective_start_date,
            effective_ending_on: irs.effective_end_date,
          )
        end
      end
      Family.new(
        id: id,
        e_case_id: e_case_id,
        family_members: family_member_objects,
        households: household_objects,
        irs_groups: irs_group_objects,
        created_at: family.created_at,
        updated_at: family.modified_at,
      )
    end

    def get_person_object_by_family_member_xml(fm)
      person = fm.person
      person_demographics = fm.person_demographics
      person_relationships = fm.person_relationships

      get_person_object_by(person, person_demographics, person_relationships, @id)
    end

    def get_coverage_households_by_household_xml(household)
      coverage_households = []
      household.coverage_households.each do |ch|
        coverage_households << CoverageHousehold.new(
          id: ch.id,
          is_immediate_family: ch.is_immediate_family == 'true',
        )
      end

      coverage_households
    end

    def get_tax_households_by_household_xml(household)
      tax_households = []
      household.tax_households.each do |th|
        tax_household_members = []
        th.tax_household_members.each do |thm|
          tax_household_members << TaxHouseholdMember.new(
            applicant_id: thm.id,
            is_ia_eligible: thm.is_insurance_assistance_eligible == 'true',
            is_medicaid_chip_eligible: thm.is_medicaid_chip_eligible == 'true',
          )
        end
        tax_households << TaxHousehold.new(
          id: th.id,
          tax_household_members: tax_household_members,
          effective_starting_on: th.start_date,
          effective_ending_on: th.end_date,
        )
      end

      tax_households
    end

    def generate_person_relationships_for_primary_applicant(family_member_objects)
      primary_applicant_person = family_member_objects.detect{|f| f.is_primary_applicant}.person rescue nil
      return if primary_applicant_person.blank?

      temp_relation = family_member_objects.map(&:person).map(&:person_relationships).flatten.compact rescue []

      temp_relation.each do |relation|
        primary_applicant_person.ensure_relationship_with(relation.person, relation.kind, family.id)
        relation.destroy
      end
    end
  end
end
