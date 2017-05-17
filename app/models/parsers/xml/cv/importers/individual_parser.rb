module Parsers::Xml::Cv::Importers
  class IndividualParser
    attr_reader :person, :person_demographics, :id, :individual

    def initialize(input_xml)
      @individual = Openhbx::Cv2::Individual.parse(input_xml, single: true)
      @id = individual.id
      @person = individual.person
      @person_demographics = individual.person_demographics
    end

    def get_person_object
      nil if person.nil? || person_demographics

      gender = person_demographics.sex.match(/gender#(.*)/)[1] rescue ''
      hbx_id = person.id.match(/hbx_id#(.*)/)[1] rescue ''

      person_object = Person.new(
        hbx_id: hbx_id,
        first_name: person.first_name,
        middle_name: person.middle_name,
        last_name: person.last_name,
        name_pfx: person.name_prefix,
        name_sfx: person.name_suffix,
        ssn: person_demographics.ssn,
        dob: person_demographics.birth_date.to_date,
        gender: gender,
        ethnicity: [person_demographics.ethnicity],
        language_code: person_demographics.language_code,
        race: person_demographics.race,
        created_at: individual.created_at,
        updated_at: individual.modified_at
      )
      person.addresses.each do |address|
        kind = address.type.match(/address_type#(.*)/)[1] rescue 'home'
        person_object.addresses.build({
          address_1: address.address_line_1,
          address_2: address.address_line_2,
          city: address.location_city_name,
          state: address.location_state_code,
          zip: address.postal_code,
          kind: kind,
        })
      end
      person.phones.each do |phone|
        phone_type = phone.type
        phone_type_for_enroll = phone_type.blank? ? nil : phone_type.strip.split("#").last
        if Phone::KINDS.include?(phone_type_for_enroll)
          person_object.phones.build({
            kind: phone_type_for_enroll,
            full_phone_number: phone.full_phone_number
          })
        end
      end
      person.emails.each do |email|
        email_type = email.type
        email_type_for_enroll = email_type.blank? ? nil : email_type.strip.split("#").last
        if ["home", "work"].include?(email_type_for_enroll)
          person_object.emails.build({
            :kind => email_type_for_enroll,
            :address => email.email_address
          })
        end 
      end
      person_object
    end

    def get_errors_for_person_object
      person = get_person_object
      return [] if person.blank?
      person.errors.full_messages
    end

    private
    def bubble_address_errors_by_person(person)
      addresses = person.addresses.select {|a| !a.valid?}
      if person.errors.has_key?(:addresses) && addresses.present?
        addresses.each do |address|
          address.errors.each do |k, v|
            person.errors.add("#{address.kind} address: #{k}", v)
          end
        end
        person.errors.delete(:addresses)
      end
    end
  end
end
