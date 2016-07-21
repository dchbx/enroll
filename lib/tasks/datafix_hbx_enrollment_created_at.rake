
namespace :datafix do
  desc "Datafix : updates all existing records where created_at is nil with current timestamp"
  task hbx_enrollment_created_at_nil: :environment do
  	families_with_enrollments_with_created_at_nil = Family.where(:"households.hbx_enrollments" => {:$exists => true }).where(:"households.hbx_enrollments.created_at" => {:$exists => 0})
  	puts "Found #{families_with_enrollments_with_created_at_nil.count} Families with enrollments.created_at is nil ."
  	families_with_enrollments_with_created_at_nil.each do |family|
  		family.households.each do |household|
  			household.hbx_enrollments.each do |enrollment|
          enrollment.set(:created_at => enrollment.submitted_at)
  			end
  		end
  	end
  end
end