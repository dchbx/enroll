require File.join Rails.root, "lib/mongoid_migration_task"

class DelinkBroker < MongoidMigrationTask

  def migrate
    hbx_id = ENV['person_hbx_id']
    legal_name = ENV['legal_name']
    organization_ids_to_move = ENV['organization_ids_to_move'].split(",") if ENV['organization_ids_to_move'].present?
    fein = ENV['fein']
    person=Person.where(hbx_id: hbx_id).first
    orgn = Organization.where(:fein => fein).first

    if orgn.nil? && person.broker_role

      #update the broker role market kind
      person.broker_role.update_attributes!(:market_kind => "both")

      hbx_office = OfficeLocation.new(
      is_primary: true, 
      address: {kind: "work", address_1: "308 Southwest Drive", address_2: "", city: "Silver Spring", state: "MD", zip: "20901" },
      phone: {kind: "main", area_code: "301", number: "593-0600"}
      )

      org = Organization.create(office_locations: [hbx_office], fein: fein, legal_name: legal_name, is_fake_fein: true)
      broker_agency_profile = BrokerAgencyProfile.create(market_kind: "both",
                                                      entity_kind: "s_corporation",
                                                      primary_broker_role_id: person.broker_role.id,
                                                      default_general_agency_profile_id: BSON::ObjectId('57339b79082e761cd1000066'),
                                                      organization: org)
      org.save
      org.broker_agency_profile.approve!
      #update fields
      person.broker_role.update_attributes!(broker_agency_profile_id: broker_agency_profile.id)
      person.broker_role.save
      #move organizations under to newly created broker agency profile 
      if organization_ids_to_move.present?
        organization_ids_to_move.each do |organization_id|
          org_er = Organization.find(organization_id)
          broker_agency_account = org_er.employer_profile.broker_agency_accounts.where(:is_active => true, :writing_agent_id => person.broker_role.id).first
          broker_agency_account.update_attributes!(broker_agency_profile_id: org.broker_agency_profile.id)
        end
      end
    else
      puts "Error for Person: #{person.first_name}" unless Rails.env.test?
    end
  end
end