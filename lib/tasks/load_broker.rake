require Rails.root.join('lib', 'tasks', 'hbx_import', 'broker', 'parsers', 'broker_parser')
require Rails.root.join('lib', 'object_builders', 'broker_role_builder')



namespace :xml do
  desc "Import brokers from xml files"
  task :broker, [:file] => :environment do |task, args|

    log_path = "#{Rails.root}/log/rake_xml_import_broker_#{Time.now.to_s.gsub(' ', '')}.log"
    rake_logger = Logger.new(log_path)

    brokers = []
    #Person.where("broker_roles.0" => { "$exists" => true }).delete_all

    begin
      xml = Nokogiri::XML(File.open(args.file))
      brokers = Parser::BrokerParser.parse(xml.root.canonicalize)
    rescue Exception => e
      puts "Failed to parse broker #{e.message}"
    end

    puts "Total number of brokers from xml: #{brokers.count}"

    counter = 0
    brokers.each do |broker|
      begin
        broker_hash = broker.to_hash
        broker_role_builder = BrokerRoleBuilder.new(broker_hash)
        broker_role_builder.build

        organization = Organization.new
        organization.legal_name = broker_hash[:organization_name]
        organization.legal_name = broker_role_builder.person.first_name + " " + broker_role_builder.person.last_name if organization.legal_name.blank?
        organization.fein = ('1'..'9').sort_by {rand}[0,9].join
        organization.build_broker_agency_profile
        organization.office_locations.build
        organization.office_locations.first.address = broker_role_builder.person.addresses.first
        organization.office_locations.first.phone = broker_role_builder.person.phones.first
        organization.office_locations.first.email = broker_role_builder.person.emails.first
        organization.broker_agency_profile.market_kind = "both"
        organization.broker_agency_profile.entity_kind = "c_corporation"
        organization.broker_agency_profile.primary_broker_role= broker_role_builder.person.broker_role
        organization.save!
        broker_role_builder.save!
        counter = counter + 1
        puts "Saved broker #{broker_role_builder.person.first_name} #{broker_role_builder.person.last_name}"
      rescue Exception => e
        puts "Failed to create broker #{broker.to_hash[:name][:first_name]} #{broker.to_hash[:name][:last_name]} \n#{e.message} #{broker_role_builder.person.errors.full_messages} \nbroker_hash#{broker.to_hash}"
      end
    end

    puts "Total number of brokers saved to database: #{counter}"
    puts "Check the log file #{log_path}"

  end
end
