namespace :migrations do
  desc "add enrollment_role_id_to_enrollment"
  task :change_reference_plan_for_employer => :environment do
    enrollment_ids = Family.collection.aggregate([{"$unwind" => '$households'},
                                                  {"$unwind" => '$households.hbx_enrollments'},
                                                  {"$match" =>
                                                          {'households.hbx_enrollments.kind' =>"employer_sponsored",
                                                           'households.hbx_enrollments.aasm_state' => {"$nin" => ['shopping', 'coverage_canceled']},
                                                           'households.hbx_enrollments.employee_role_id'=> {"$exists" => false}
                                                          }
                                                  },
                                                  {"$group" => { "_id" => "$households.hbx_enrollments.hbx_id" }},
                                                  {"$project" => {'_id' => 1}}],:allow_disk_use => true).collect{|result|result['_id']}
    enrollment_ids.each do |hbx_id|
      hbx_enrollment = HbxEnrollment.by_hbx_id(hbx_id).first
      if hbx_enrollment.nil?
        puts "no enrollment found for #{hbx_id}"
        next
      end
      bga= hbx_enrollment.benefit_group_assignment
      if bga.nil?
        puts "No benefit group assgnment for enrollment #{hbx_id}"
        next
      end
      ce = bga.census_employee
      ee = ce.employee_role
      if ee.nil?
        puts "No employee role found for enrollment #{hbx_id}"
      else
        unless hbx_enrollment.update_attributes(employee_role_id:ee.id)
          puts "Employee Role not updated on #{hbx_id}"
        end
      end
    end
  end
end
