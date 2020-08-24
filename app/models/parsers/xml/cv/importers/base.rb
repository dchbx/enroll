module Parsers::Xml::Cv::Importers
  module Base
    def get_person_object_by(person, person_demographics, person_relationships, family_id)
      hbx_id = person.id.strip.split('#').last rescue ''
      gender = person_demographics.sex.match(/gender#(.*)/)[1] rescue ''

      person_object = Person.new(
        id: hbx_id,
        hbx_id: hbx_id,
        first_name: person.first_name,
        middle_name: person.middle_name,
        last_name: person.last_name,
        name_pfx: person.name_prefix,
        name_sfx: person.name_suffix,
        ssn: person_demographics.ssn,
        dob: person_demographics.birth_date.try(:to_date),
        gender: gender,
        ethnicity: [person_demographics.ethnicity],
        language_code: person_demographics.language_code,
        race: person_demographics.race,
      )
      person_relationships.each do |relationship|
        next if relationship.subject_individual == relationship.object_individual
        relation = relationship&.relationship_uri&.strip&.split("#")&.last
        person_object.person_relationships.build({successor_id: relationship.object_individual, #use subject_individual or object_individual
                                                  predecessor_id: person_object.id,
                                                  family_id: family_id,
                                                  kind: PersonRelationship::InverseMap[relation]})
                                                  # relative_id: relationship.object_individual, #use subject_individual or object_individual
                                                  # kind: relation
      end

      build_addresses(person, person_object)
      build_phones(person, person_object)
      build_emails(person, person_object)

      person_object
    end

    def build_addresses(person, person_object)
      person.addresses.each do |address|
        kind = 'home'
        begin
          kind = address.type.match(/address_type#(.*)/)[1]
        rescue StandardError
          kind = 'home'
        end
        person_object.addresses.build({address_1: address.address_line_1,
                                       address_2: address.address_line_2,
                                       city: address.location_city_name,
                                       state: address.location_state_code,
                                       zip: address.postal_code,
                                       kind: kind})
      end
    end

    def build_phones(person, person_object)
      person.phones.each do |phone|
        phone_type = phone.type
        phone_type_for_enroll = phone_type.blank? ? nil : phone_type.strip.split("#").last
        next if Phone::KINDS.include?(phone_type_for_enroll)
        person_object.phones.build({kind: phone_type_for_enroll,
                                    full_phone_number: phone.full_phone_number})
      end
    end

    def build_emails(person, person_object)
      person.emails.each do |email|
        email_type = email.type
        email_type_for_enroll = email_type.blank? ? nil : email_type.strip.split("#").last
        if ["home", "work"].include?(email_type_for_enroll)
          person_object.emails.build({:kind => email_type_for_enroll,
                                      :address => email.email_address})
        end
      end
    end
  end
end
