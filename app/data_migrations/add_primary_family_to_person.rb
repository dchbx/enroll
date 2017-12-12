require File.join(Rails.root, "lib/mongoid_migration_task")

class AddPrimaryFamilyToPerson < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['hbx_id'].to_s
      person=Person.where(hbx_id: hbx_id).first
      primary_family = person.primary_family
      if primary_family.present?
        puts "primary family already present"
      else
        family = Family.new(:is_active => true)
        family.family_members.new(is_primary_applicant: true, is_coverage_applicant: true, is_consent_applicant: false, is_active: true, person_id: person.id)
        family.save
        person.person_relationships.each do |pr|
          if Person.where(:id => pr.relative_id).count > 0
            family.family_members.new(is_primary_applicant: false, is_coverage_applicant: true, is_consent_applicant: false, is_active: true, person_id: pr.relative_id)
          end
        end
        family.save
        puts "created primary family for hbx_id: #{ENV['hbx_id']} with primary_family_id : #{person.primary_family}" unless Rails.env.test?
      end
    rescue
      puts "Bad Record" unless Rails.env.test?
    end
  end
end