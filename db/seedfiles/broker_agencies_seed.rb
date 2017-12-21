puts "*"*80
puts "::: Generating Broker Agencies:::"
require 'broker_parser'

p0 = Person.where(last_name: "Murray").first
p1 = Person.where(last_name: "Chase").first
p3 = Person.where(last_name: "Curtin").first
bk1 = BrokerRole.find_by_npn("2068981")
bk0 = BrokerRole.find_by_npn("1682443")

supported_state_abbreviation = Settings.aca.state_abbreviation
supported_market_type = Settings.aca.market_kinds.count == 2 ? 'both' : Settings.aca.market_kinds.first

office0 = OfficeLocation.new(address: {kind: "work", address_1: "101 Main St", city: "Washington", state: supported_state_abbreviation, zip: "20001"}, phone: {kind: "work", area_code: "202", number: "555-1212"})
org0 = Organization.new(legal_name: "ACME Agency", fein: "034267010", office_locations: [office0], dba: "Acme")
org0.create_broker_agency_profile(primary_broker_role: bk0, market_kind: supported_market_type, entity_kind: "c_corporation")

office1 = OfficeLocation.new(address: {kind: "work", address_1: "102 Main St", city: "Washington", state: supported_state_abbreviation, zip: "20001"}, phone: {kind: "work", area_code: "202", number: "555-1213"})
org1 = Organization.new(legal_name: "Chase & Assoc", fein: "034267001", office_locations: [office1], dba: "Chase")
org1.create_broker_agency_profile(primary_broker_role: bk1, broker_agency_contacts: [p1, p3], market_kind: supported_market_type, entity_kind: "c_corporation")

p0.broker_role.broker_agency_profile_id  = org1.broker_agency_profile.id
p0.broker_role.save!
p3.broker_role.broker_agency_profile_id  = org1.broker_agency_profile.id
p3.broker_role.save!

broker_files = Dir.glob("#{Rails.root}/public/xml/brokerxmls/*")
broker_files.each do |file|
  file_contents = File.read(file)
  broker_records = BrokerParser.parse(file_contents)

  broker_records.each do |broker_record|
    vcard = broker_record.vcard
    address = vcard.broker_address
    loc_address = Address.new(kind: address.parameter.type.text, address_1: address.street, city: address.locality, state: address.region, zip: address.code)

    phone = vcard.broker_phone
    raw_number = phone.uri
    raw_number = raw_number.gsub! "tel:+1-",""
    area_code = raw_number.split("-")[0]
    phone_number = raw_number.split("-")[1]+raw_number.split("-")[2]
    loc_phone = Phone.new(kind: phone.parameter.type.text, area_code: area_code, number: phone_number)

    email = vcard.broker_email
    loc_email = Email.new(kind: phone.parameter.type.text, address: email.text)

    office_location = OfficeLocation.new(address: loc_address, email: loc_email, phone: loc_phone)

    org1 = Organization.new(legal_name: vcard.org, fein: "034267001", office_locations: [office_location])

    vcard_person = vcard.person
    if vcard_person.surname.present? && vcard_person.given.present?
      person = Person.where(last_name: vcard_person.surname)
      if person.present?
        person = person.first
        if person.broker_role.blank?
          broker_role = BrokerRole.new(npn: broker_record.npn, provider_kind: "broker")
          person.broker_role = broker_role
          person.save!
        end
      else
        broker_role = BrokerRole.new(npn: broker_record.npn, provider_kind: "broker")
        person = Person.new(first_name: vcard_person.given, last_name: vcard_person.surname)
        person.save!
        person.broker_role = broker_role
        person.save!
      end
      org1.create_broker_agency_profile(primary_broker_role: person.broker_role, market_kind: "both", broker_agency_contacts: [person], entity_kind: "c_corporation")
    end
  end
end

puts "::: Broker Agencies Complete :::"
puts "*"*80
