# frozen_string_literal: true

module Services
  class FamilyService

    def self.call(family)
      new.execute(family: family)
    end

    def execute(family:)
      family.family_members.collect {|family_member| person_attributes(family_member.person).merge(family_member_id: family_member.id) }
    end

    def person_attributes(person)
      attrs = person.attributes.slice(:first_name,:last_name,:middle_name,:name_pfx,:name_sfx,:dob,:ssn,:gender, :ethnicity, :tribal_id, :no_ssn)

      attrs.merge({
                    is_applying_coverage: person.consumer_role.is_applying_coverage,
                    us_citizen: person.consumer_role.us_citizen,
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