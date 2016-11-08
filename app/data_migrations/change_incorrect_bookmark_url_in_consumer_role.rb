require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeIncorrectBookmarkUrlInConsumerRole < MongoidMigrationTask
  def migrate
    Person.all.each do |person|
      begin
        if person.has_active_consumer_role?&& person.user.present?
          if person.primary_family.present? && person.primary_family.active_household.present? && person.primary_family.active_household.hbx_enrollments.where(kind: "individual", is_active: true).present?
            if person.user.identity_verified? && person.user.idp_verified && (person.addresses.present? || person.no_dc_address.present? || person.no_dc_address_reason.present?)
              puts " HBX_ID: #{person.hbx_id}, OLD_URL: #{person.consumer_role.bookmark_url}, NEW_URL: '/families/home' " if  person.consumer_role.bookmark_url.present? && person.consumer_role.bookmark_url !=  "/families/home" && !Rails.env.test?
              person.consumer_role.update_attribute(:bookmark_url, "/families/home")
            end
          end
        end
      rescue
      end
    end
  end
end
