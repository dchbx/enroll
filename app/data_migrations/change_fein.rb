require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeFein< MongoidMigrationTask
  def migrate
    trigger_single_table_inheritance_auto_load_of_child = VlpDocument

    wrong_fein = ENV['old_fein']
    right_fein = ENV['new_fein']

    correct_org = Organization.where(fein: wrong_fein).first
    deprecated_org = Organization.where(fein: right_fein).first

    if correct_org.nil?
      puts "No organization was found by the given fein: #{wrong_fein}" unless Rails.env.test?
    else
      if deprecated_org.present?
        deprecated_org.unset(:fein)
        correct_org.set(fein: right_fein)
        deprecated_org.set(fein: wrong_fein)
        puts "Swapped fein from #{wrong_fein} to #{right_fein}" unless Rails.env.test?
      else
        correct_org.update_attributes(fein: right_fein)
        puts "Changed fein to #{right_fein}" unless Rails.env.test?
      end
    end
  end
end
