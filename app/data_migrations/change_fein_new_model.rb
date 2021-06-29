# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeFeinNewModel < MongoidMigrationTask
  def migrate
    wrong_fein = ENV['old_fein']
    right_fein = ENV['new_fein']

    correct_exempt_org = BenefitSponsors::Organizations::ExemptOrganization.where("fein" => wrong_fein).first
    deprecated_exempt_org = BenefitSponsors::Organizations::ExemptOrganization.where("fein" => right_fein).first

    if correct_exempt_org.nil?
      puts "No organization was found by the given fein: #{wrong_fein}" unless Rails.env.test?
    elsif deprecated_exempt_org.present?
      raise "organization with fein #{right_fein} already present"
    else
      correct_exempt_org.update_attributes(fein: right_fein)
      puts "Changed fein for #{correct_exempt_org.legal_name} to #{correct_exempt_org.fein} in new model" unless Rails.env.test?
    end
  end
end
