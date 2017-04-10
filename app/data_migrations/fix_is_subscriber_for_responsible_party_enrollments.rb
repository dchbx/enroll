require File.join(Rails.root, 'lib/mongoid_migration_task')

class FixIsSubscriberForResponsiblePartyEnrollments < MongoidMigrationTask
  def migrate
    invalid_is_subscriber_enrollment_ids.each.with_index(1) do |enrollment_id, idx|
      HbxEnrollment.find(enrollment_id).save
      puts "#{idx}: Changed the is_subscriber flag for HbxEnrollment ID #{enrollment_id} to true." unless Rails.env.test?
    end
  end

  private

  def invalid_is_subscriber_enrollment_ids
    Family.collection.aggregate(
      [
        {'$unwind' => '$households'},
        {'$unwind' => '$households.hbx_enrollments'},
        {'$unwind' => '$households.hbx_enrollments.hbx_enrollment_members'},
        {'$match' => {
          'households.hbx_enrollments' => {'$ne' => nil}
        }},
        {'$match' => {
          'households.hbx_enrollments.hbx_enrollment_members' => {'$ne' => nil},
          'households.hbx_enrollments.external_enrollment' => {'$ne' => true}
        }},
        {'$match' => {
          'households.hbx_enrollments.aasm_state' => {'$ne' => 'shopping'}
        }},
        {'$match' => {
          'households.hbx_enrollments.plan_id' => {'$ne' => nil},
          'households.hbx_enrollments.aasm_state' => {'$nin' => ['shopping', 'inactive', 'coverage_canceled', 'coverage_terminated']}
        }},
        {'$group' => {
          '_id' => '$households.hbx_enrollments._id',
          'max_hbx_enrollment_member' => {'$max' => '$households.hbx_enrollments.hbx_enrollment_members.is_subscriber'}
        }},
        {'$match' => {
          'max_hbx_enrollment_member' => false
        }}
      ],
      :allow_disk_use => true
    ).to_a.map { |enrollment| enrollment['_id'].to_s }
  end
end
