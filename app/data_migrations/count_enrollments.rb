require File.join(Rails.root, "lib/migration_task")

class CountEnrollments < MigrationTask 

  def get_counts
    orgs = Organization.where('employer_profile' => {"$exists" => true})
    a = Time.now
    orgs.no_timeout.each {|org|
      latest_plan_year = org.employer_profile.latest_plan_year
      if latest_plan_year
        b = Time.now
        latest_plan_year.update_attributes(enrolled_summary: latest_plan_year.total_enrolled_count, waived_summary: latest_plan_year.waived_count)
        puts "Count #{latest_plan_year.waived_count}, #{Time.now - b}"
      end
    }
    puts "Done #{Time.now - a}"
  end
end