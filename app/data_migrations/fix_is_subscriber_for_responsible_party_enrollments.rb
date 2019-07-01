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
    HbxEnrollment.collection.aggregate(
      [
        {'$match' => {
          'hbx_enrollment_members' => {'$ne' => nil},
          'external_enrollment' => {'$ne' => true}
        }},
        {'$match' => {
          'aasm_state' => {'$ne' => 'shopping'}
        }},
        {'$match' => {
          'plan_id' => {'$ne' => nil},
          'aasm_state' => {'$nin' => ['shopping', 'inactive', 'coverage_canceled', 'coverage_terminated']}
        }},
        {'$group' => {
          '_id' => '$_id',
          'max_hbx_enrollment_member' => {'$max' => '$hbx_enrollment_members.is_subscriber'}
        }},
        {'$match' => {
          'max_hbx_enrollment_member' => false
        }}
      ],
      :allow_disk_use => true
    ).to_a.map { |enrollment| enrollment['_id'].to_s }
  end
end
