require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectPlanInEnrollment < MongoidMigrationTask

  def migrate
    batch_size = 500
    offset = 0

    while (offset < Family.count)
      Family.offset(offset).limit(batch_size).each do |family|
        family.households.flat_map(&:hbx_enrollments).each do |hbx_enrollment|

          begin
            next if (["shopping", "void"].include? hbx_enrollment.aasm_state)
            next if hbx_enrollment.plan.nil?
            next if hbx_enrollment.kind != 'individual'

            fix_enrollment(hbx_enrollment)
          rescue Exception => e
            puts "Family #{family.id} #{e.message}"
          end
        end
      end
      offset = offset + batch_size
    end
  end

  def fix_enrollment(hbx_enrollment)
    if hbx_enrollment.effective_on.year != hbx_enrollment.plan.active_year
      hbx_enrollment.plan = correct_plan(hbx_enrollment)
      hbx_enrollment.save!
    end
    hbx_enrollment
  end

  def correct_plan(hbx_enrollment)
    Plan.where({hios_id: hbx_enrollment.plan.hios_id, active_year: hbx_enrollment.effective_on.year}).first
  end
end
