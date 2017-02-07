require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class DestroyDuplicatesWithoutEnr < MongoidMigrationTask
  def migrate

field_names  = %w(Person_HBX_ID Primary_subscriber_HBX_ID)

Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
file_name = "#{Rails.root}/hbx_report/destroy_duplicates_without_enr.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      Family.all.each do |family|
        family_members = family.family_members
        if family_members.present? && family_members.size > 2
          duplicate_member_person_ids = family_members.collect{|f| f.person_id.to_s}.select { |e| family_members.collect{|f| f.person_id.to_s}.count(e) > 1}.uniq
          unless duplicate_member_person_ids.blank?
            primary_subscriber_hbx_id = family.primary_applicant.hbx_id
            family_members_ids = []
            duplicate_member_person_ids.each do |p|
              family_members_ids << family.family_members.select { |fm| fm.person_id.to_s == p}.map(&:id)
            end
            all_members_to_delete =[]
            if family.enrollments.blank?
              family_members_ids.each do |dup_fam|
                  dup_fam.shift
                  all_members_to_delete << dup_fam
                  all_members_to_delete.flatten!
                  family_members.any_in(:id => dup_fam).each do |d|
                    csv << [d.hbx_id, primary_subscriber_hbx_id
                    ]
                  end
                end
            end
            family.active_household.coverage_households.each do |chm|
              chm.coverage_household_members.to_a.each do |chm_member|
                if all_members_to_delete.include? chm_member.family_member_id
                  chm_member.destroy!
                  chm.save!
                end
              end
            end
            family_members.any_in(:id => all_members_to_delete).destroy_all
          end
        end
      end
    end
  end
end
