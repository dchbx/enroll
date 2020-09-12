# frozen_string_literal: true

module Services
  class FamilyService

    def self.call(family_id)
      family = Family.find(family_id)
      new.execute(family: family)
    end

    def execute(family:)
      family.family_members.collect {|family_member|  family_member_attributes(family_member)}
    end

    def family_member_attributes(family_member)
      person_attributes(family_member.person).merge(
        family_member_id: family_member.id,
        is_primary_applicant: family_member.is_primary_applicant)
    end

    def person_attributes(person)
      attrs = person.attributes.slice(:first_name, :last_name, :middle_name, :name_pfx, :name_sfx, :dob, :ssn, :gender, :ethnicity, :tribal_id, :no_ssn)

      attrs.merge({
                    person_hbx_id: person.hbx_id,
                    is_applying_coverage: person.consumer_role.is_applying_coverage,
                    citizen_status: person.citizen_status,
                    is_consumer_role: true,
                    indian_tribe_member: person.consumer_role.is_tribe_member?,
                    is_incarcerated: person.is_incarcerated,
                    addresses_attributes: construct_association_fields(person.addresses),
                    phones_attributes: construct_association_fields(person.phones),
                    emails_attributes: construct_association_fields(person.emails)
                  })
    end

    def construct_association_fields(records)
      records.collect{|record| record.attributes.except(:_id, :created_at, :updated_at, :tracking_version) }
    end
  end
end