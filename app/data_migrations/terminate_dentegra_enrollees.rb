require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateDentegraEnrollees < MongoidMigrationTask
  def migrate
    puts "*"*80 unless Rails.env.test?
    puts "terminate dentegra enrollees started" unless Rails.env.test?
    Person.all_consumer_roles.each do |person|
      begin
        family = person.primary_family
        if family.present?
          enrollments = family.enrollments
          if enrollments.present?
            enrollments.each do |enrollment|
              if enrollment.present? && enrollment.effective_on.year == 2016 && enrollment.plan.carrier_profile_id.to_s == "53e67210eb899a4603000013"
                termination_date = "2016-12-31".to_date
                enrollment.set_coverage_termination_date(termination_date)
                enrollment.schedule_coverage_termination
                puts "person #{person.full_name} enrollment terminated." unless Rails.env.test?
              end
            end
          end
        end
      rescue Exception => e
        puts "#{e.message}"
      end
    end
    puts "terminate dentegra enrollees finished" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end
end