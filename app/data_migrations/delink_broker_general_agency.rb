require File.join(Rails.root, "lib/mongoid_migration_task")
class DelinkBrokerGeneralAgency < MongoidMigrationTask
  def migrate

    ga_org = Organization.where(fein: "521698168").first
    ga_org.update_attributes!(:legal_name => "Insurance Marketing Center", :dba => "Insurance Marketing Center")
    # br_id = ga_org.broker_agency_profile.id

    ga_address = ga_org.office_locations.first.address
    ga_address.update_attributes!(:address_1 => "1101 Wootton Parkway Suite 820", :city => "Rockville", :state => 'MD', :zip => "20852")

    ga_org.broker_agency_profile.delete
    ga_org.reload

    if ga_org.broker_agency_profile.blank?
      puts "Updated General agency information and deleted old Broker agency profile" unless Rails.env.test?
    end

    address = Address.new(kind: 'primary', address_1: '106 Autumn Hill Way', address_2: '', address_3: '', city: 'Gaithersburg', county: nil, state: 'MD', location_state_code: nil, zip: '20877', country_name: '', full_text: nil)
    phone = Phone.new(kind: 'work', country_code: '', area_code: '301', number: '9227984', extension: '', primary: nil, full_phone_number: '3019227984')
    office_location = OfficeLocation.new(is_primary: true, address: address, phone: phone)

    organization = Organization.new(:legal_name => "Alvin Frager", :fein => "521376450", :dba => "Alvin Frager Insurance", office_locations: [office_location])
    broker_agency_profile = BrokerAgencyProfile.new(:id => BSON::ObjectId('57961bf1f1244e3ece000064'), :organization => organization,entity_kind: "s_corporation", market_kind: "shop", corporate_npn: nil, primary_broker_role_id: BSON::ObjectId('57961bf1f1244e3ece000062'), default_general_agency_profile_id: BSON::ObjectId('57589d8bf1244e54170000ab'), languages_spoken: ["", "en"], working_hours: true, accept_new_clients: true, aasm_state: "is_approved")

    puts "created new broker agency profile and delinked GA & BA." unless Rails.env.test?
    organization.save
  end
end
