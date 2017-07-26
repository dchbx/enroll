require File.join(Rails.root, "lib/mongoid_migration_task")

class BuildIvlEnrollment < MongoidMigrationTask
  def migrate
    begin
      people = Person.where(hbx_id: ENV['person_hbx_id'])
      if people.size !=1 
        puts "Check hbx_id. Found no (or) more than 1 persons" unless Rails.env.test?
        raise
      end
      person = people.first
      consumer_role = person.consumer_role
      if consumer_role.blank?
        puts "this person don't have a consumer role" unless Rails.env.test?
        return
      end
      effective_on = Date.strptime(ENV['effective_on'].to_s, "%m/%d/%Y")
      new_hbx_id = ENV['new_hbx_id'].to_s
      hios_id = ENV['hios_id'].to_s
      active_year = ENV['active_year']
      aptc = ENV['aptc_in_cents']
      if aptc.present? && person.primary_family.active_household.tax_households.blank?
        puts "oops!! No tax household present. This is not an assisted family" unless Rails.env.test?
        return
      end
      if hios_id.present? && active_year.present?
        plan = Plan.where(hios_id: hios_id, active_year: active_year).first
        if plan.nil?
          puts "This Plan details you entered are incorrect" unless Rails.env.test?
          return
        end
      else
        puts "provide plan details" unless Rails.env.test?
        return
      end
      
      enrollment = HbxEnrollment.new(kind: "individual", consumer_role_id: consumer_role.id)
      enrollment.effective_on = effective_on
      enrollment.plan_id = plan.id
      enrollment.applied_aptc_amount = {"cents"=> aptc, "currency_iso"=>"USD"}
      family_members = person.primary_family.active_family_members.select { |fm| Family::IMMEDIATE_FAMILY.include? fm.primary_relationship }
      family_members.each do |fm|
        hem = HbxEnrollmentMember.new(applicant_id: fm.id, is_subscriber: fm.is_primary_applicant,
                                      eligibility_date: enrollment.effective_on, coverage_start_on: enrollment.effective_on
                                     )
        enrollment.hbx_enrollment_members << hem
        puts "Added coverage for #{fm.person.full_name}" unless Rails.env.test?
      end
      person.primary_family.active_household.hbx_enrollments << enrollment
      person.primary_family.active_household.save!
      enrollment.select_coverage! if enrollment.may_select_coverage?
      if new_hbx_id.present?
        enrollment.update_attributes!(hbx_id: new_hbx_id)
      end
      puts "Created a new Ivl enrollment with the given effective_on date & hbx_id is #{enrollment.hbx_id}" unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end
