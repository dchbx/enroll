require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCarrierNames < MongoidMigrationTask
  def migrate

    org_hash = {
      "237442369" => "Fallon Health",
      "042864973" => "Health New England",
      "453596033" => "Minuteman Health",
      "043373331" => "BMC HealthNet Plan"
    }

    org_hash.each do |fein, legal_name|
      org = Organization.where(fein: fein).last
      org.update_attributes(legal_name: legal_name) if org.present?
    end

  end
end