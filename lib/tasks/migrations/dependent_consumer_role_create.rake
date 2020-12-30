namespace :migrations do
  desc "create missing consumer roles for dependents"
  task :dependent_consumer_role_create, [:hbx_id] => :environment do |t, args|

    begin
      person = Person.where(hbx_id: args[:hbx_id].to_s).first
     family = person&.primary_family

      # next if primary.employee_roles.any?
      next if person.consumer_role.blank?
      next if family.blank?
      active_family_members = family.active_family_members

      active_family_members.each do |member|
        if member.person.consumer_role.blank?
          puts "creating consumer role for #{member.person.full_name}"

          Factories::EnrollmentFactory.add_consumer_role(
            person: member.person,
            new_is_incarcerated: 'false',
            new_is_state_resident: true,
            new_is_applicant: 'false',
            new_citizen_status: "us_citizen"
            )
        end
      end
    rescue Exception => e
      puts "Exception #{e} occured for family #{family.e_case_id}"
    end
  end
end

