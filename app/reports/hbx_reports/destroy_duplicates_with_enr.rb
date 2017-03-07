require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class DestroyDuplicatesWithEnr < MongoidMigrationTask
  def migrate
    field_names  = %w(Person_HBX_ID Primary_subscriber_HBX_ID Enrollment_HBX_ID Enrollment_aasm_state)
    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/destroy_duplicates_with_enr.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      Family.all.each do |family|
        begin
          family_members = family.family_members
          if family_members.present? && family_members.size > 2
            duplicate_member_person_ids = family_members.collect{|f| f.person_id.to_s}.select { |e| family_members.collect{|f| f.person_id.to_s}.count(e) > 1}.uniq
            family_members_ids = []
            primary_subscriber_hbx_id = family.primary_applicant.hbx_id
            unless duplicate_member_person_ids.blank?
              duplicate_member_person_ids.each do |p|
                family_members_ids << family.family_members.select { |fm| fm.person_id.to_s == p}.map(&:id)
              end
            end

            if family.enrollments.count > 0
              family_members_ids.each do |dup_fam_mem|
                member_to_stay = dup_fam_mem.shift
                family.enrollments.each do |enrollment|
                  family_members.any_in(:id => dup_fam_mem).each do |d|
                    csv << [d.hbx_id, primary_subscriber_hbx_id, enrollment.hbx_id, enrollment.aasm_state
                    ]
                  end
                  enrollment.hbx_enrollment_members.any_in(:applicant_id => dup_fam_mem).update_all(:applicant_id => member_to_stay)
                  enrollment.hbx_enrollment_members.where(:applicant_id => member_to_stay).skip(1).each do |member|
                    member.destroy
                  end
                end

                family.active_household.coverage_households.each do |chm|
                  chm.coverage_household_members.each do |chm_member|
                    if dup_fam_mem.include? chm_member.family_member_id
                      chm_member.update_attributes({:family_member_id => member_to_stay})
                    end
                  end
                  chm.coverage_household_members.where(:family_member_id => member_to_stay).skip(1).each do |member|
                    member.destroy
                  end
                end

                family_members.any_in(:id => dup_fam_mem).destroy_all
              end
            end
          end
        rescue
          puts "Bad family record #{family.id}" unless Rails.env.test?
        end
      end
    end
  end
end
