#8354, updating the aasm_state of this employer(Anytime Canine) because this employer was created manually.
namespace :update do
  task :employer_status_to_enrolled => :environment do
    organization = Organization.where(legal_name: /Anytime Canine/)
    empr = organization.last.employer_profile
    puts "*"*80
    puts "found employer : #{empr.legal_name} "
    empr.aasm_state = "enrolled"
    if empr.valid?
      empr.save
      puts "successfully updated the aasm_state of #{empr.legal_name} to #{empr.aasm_state}"
    end
    puts "*"*80
  end
end