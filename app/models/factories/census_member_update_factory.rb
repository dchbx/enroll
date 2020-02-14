# frozen_string_literal: true

# This factory is used to update the CensusMemebers.
# Currently Applied: Family Member updates from UI.

module Factories
  class CensusMemberUpdateFactory

    EMPLOYEE_RELATIONSHIP_KINDS = ['spouse', 'domestic_partner', 'child', 'child_under_26', 'child_26_and_over', 'disabled_child_26_and_over'].freeze

    def update_census_employee_records(person)
      person.active_employee_roles.each do |role|
        update_record(person, role.census_employee)
      end
    end

    def update_census_dependent_records(person, family_member)
      return if person.families.blank?

      employee_roles = family_member.family.primary_person.active_employee_roles
      employee_roles.each do |role|
        census_dependent = role.census_employee.census_dependents.where(matching_criteria(person)).first
        update_record(person, census_dependent) if census_dependent.present?
      end
    end

    def update_census_dependent_relationship(existing_relationship)
      return unless EMPLOYEE_RELATIONSHIP_KINDS.include?(existing_relationship.kind)

      primary_person = existing_relationship.person
      dependent_person = existing_relationship.relative

      primary_person.active_employee_roles.each do |role|
        census_dependent = role.census_employee.census_dependents.where(matching_criteria(dependent_person)).first
        census_dependent.update_attributes(employee_relationship: existing_relationship.kind) if census_dependent.present?
      end
    end

    def create_census_dependent(family_member)
      employee_roles = family_member.family.primary_person.active_employee_roles
      return unless employee_roles.present? && EMPLOYEE_RELATIONSHIP_KINDS.include?(family_member.relationship)

      person = family_member.person
      employee_roles.each do |role|
        census_dependents = role.census_employee.census_dependents
        census_dependents.where(first_name: person.first_name, last_name: person.last_name, dob: person.dob, gender: person.gender).first_or_create do |census_dependent|
          census_dependent.encrypted_ssn = person.encrypted_ssn
          census_dependent.middle_name = person.middle_name
          census_dependent.name_sfx = person.name_sfx
          census_dependent.employee_relationship = build_relationship(family_member)
          census_dependent.address = family_member.person.home_address
          census_dependent.email = family_member.person.work_or_home_email
        end
      end
    end

    private

    def update_record(person, record)
      record.update_attributes(build_updated_value_hash(person.changes, required_person_attributes)) if person.changed_attributes

      record.address.update_attributes(build_updated_value_hash(person.mailing_address.changes)) if person.mailing_address&.changes && record.address

      email_changes = person.work_or_home_email.changes if person.work_or_home_email
      record.email.update_attributes(build_updated_value_hash(email_changes)) if email_changes.present?
    end

    def build_relationship(family_member)
      if family_member.relationship == 'child' && family_member.person.age_on(TimeKeeper.date_of_record) < 26
        'child_under_26'
      elsif family_member.relationship == 'child'
        'child_26_and_over'
      else
        family_member.relationship
      end
    end

    def required_person_attributes
      ['first_name', 'middle_name', 'last_name', 'name_sfx', 'dob', 'encrypted_ssn', 'gender']
    end

    def matching_criteria(person)
      criteria =
        {
          'first_name' => person.first_name,
          'last_name' => person.last_name,
          'dob' => person.dob
        }
      criteria.keys.each do |changed_attr|
        person.changes.each do |k, v|
          criteria[changed_attr] = v[0] if k == changed_attr
        end
      end
      criteria
    end

    def build_updated_value_hash(attr_changes, req_attrs = nil)
      updated_values = { }
      attr_changes.each do |k, v|
        updated_values[k] = v[1] if req_attrs.nil? || req_attrs&.include?(k)
      end
      updated_values
    end
  end
end