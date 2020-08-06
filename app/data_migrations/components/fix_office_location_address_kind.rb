# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class FixOfficeLocationAddressKind < MongoidMigrationTask
  def migrate
    BenefitSponsors::Organizations::Organization.all.employer_profiles.each do |organization|
      organization.employer_profile.office_locations.each do |office_location|
        next unless office_location.is_primary && office_location.address.kind == "work"
        BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.skip_callback(:update, :after, :notify_observers)
        BenefitSponsors::Organizations::Profile.skip_callback(:save, :after, :publish_profile_event)
        office_location.address.update_attributes(kind: 'primary')
        BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.set_callback(:update, :after, :notify_observers)
        BenefitSponsors::Organizations::Profile.set_callback(:save, :after, :publish_profile_event)
      end
    end
  end
end
