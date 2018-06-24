#This rake task will update the eligibility kinds (is_ia_eligible and is_medicaid_chip_eligible) of a thhm.
#RAILS_ENV=production bundle exec rake task:thhm:update_eligibility_kinds primary_hbx_id=12345 dependent_hbx_id=132445 eligibility_kinds=is_ia_eligible:true,is_medicaid_chip_eligible:false
#In the above rake task true/false can be replaced with t/f, 1/0, yes/no, y/n
#primary_hbx_id and dependent_hbx_id can be same, in case you are updating for the primary.
#Run this rake task after executing this rake create_tax_household with the appropriate fields.

namespace :task do
  namespace :thhm do
    desc "Update tax household member's eligibility kinds"
    task :update_eligibility_kinds => :environment do

      dependent_hbx_id = ENV['dependent_hbx_id'].to_s
      primary_hbx_id = ENV['primary_hbx_id'].to_s
      eligibility_kinds = ENV['eligibility_kinds']

      eligibility_kinds_hash = {}
      eligibility_kinds.split(",").each do |eligibility_kind|
        key = eligibility_kind.split(":").first # eligibility_kind type
        val = eligibility_kind.split(":").second # eligibility_kind value
        eligibility_kinds_hash[key]=val
      end

      person = Person.by_hbx_id(primary_hbx_id).first rescue nil
      dependent = Person.by_hbx_id(dependent_hbx_id).first rescue nil

      if person.present? && dependent.present?
        if person.primary_family.present?
          primary_family = person.primary_family
          family_members = primary_family.family_members.where(person_id: dependent.id)

          if family_members.count == 1
            family_member = family_members.first
            family_member_id = family_member.id if family_member.present?

            active_household = primary_family.active_household
            latest_active_thh = active_household.latest_active_thh
            tax_household_member = latest_active_thh.tax_household_members.where(applicant_id: family_member_id).first
            status = tax_household_member.update_eligibility_kinds(eligibility_kinds_hash) if latest_active_thh.present?

            if status
              puts "Eligibilitiy Kinds for THHM updated successfully" unless Rails.env.test?
            else
              puts "Eligibilitiy Kinds for THHM failed to update" unless Rails.env.test?
            end
          else
            puts "No/Duplicate Family Members found with the dependent hbx id: #{dependent_hbx_id}" unless Rails.env.test?
          end
        else
          puts "No Primary family for the supplied Primary HBX ID" unless Rails.env.test?
        end
      else
        puts "Person or Dependent not found." unless Rails.env.test?
      end
    end
  end
end