require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateOfficeLocation < MongoidMigrationTask
  def migrate
    begin
      org_hbx_id = ENV['org_hbx_id']
      address_kind = (ENV['address_kind']).to_s # primary/mailing/etc

      attrs = {}
      attrs['address_1'] = (ENV['address_1']).to_s if ENV['address_1'].present?
      attrs['city'] = (ENV['city']).to_s if ENV['city'].present?
      attrs['zip'] = (ENV['zip']).to_s if ENV['zip'].present?
      attrs['state'] = (ENV['state_code']).to_s if ENV['state_code'].present?

      org = BenefitSponsors::Organizations::Organization.find_by(hbx_id: org_hbx_id)

      if org.nil?
         puts "no organization found with given hbx_id" unless Rails.env.test?
         return
      end

      # State is not validated in address model, but if its present, we should assure it is submitted as abbreviation
      if attrs['state'].present? && attrs['state'].length > 2
        puts "States should be submitted with their abbreviation format, I.E. 'MD' instead of 'Maryland'." unless Rails.env.test?
        return
      end

      location_found = false
      org.broker_agency_profile.office_locations.each do |office|
        if office.address.kind == address_kind
          office.address.update_attributes!(attrs)
          office.address.save!
          location_found = true
          puts "#{address_kind} office location updated" unless Rails.env.test?
        end
      end
      puts "#{address_kind} office location not found" unless location_found || Rails.env.test?

    rescue => e
      puts e.message unless Rails.env.test?
    end
  end
end
