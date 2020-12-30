# This rake task used to generate weekly report of dependent relationship changes.
# To run task: RAILS_ENV=production rake reports:dependent:relationship_change_weekly_report

require 'csv'

namespace :reports do
  namespace :dependent do

    desc "depenedent relationship change report"
    task :relationship_change_weekly_report => :environment do
      include Config::AcaHelper

      date_range = (TimeKeeper.start_of_exchange_day_from_utc(TimeKeeper.date_of_record) - 7.days)..TimeKeeper.end_of_exchange_day_from_utc(TimeKeeper.date_of_record)
      people = Person.unscoped.where(:person_relationships.exists => true, :person_relationships => {"$elemMatch" => {"updated_at" => date_range}})

      field_names  = %w(
        Subscriber_HBX_ID
        Subscriber_First_Name
        Subscriber_Last_Name
        Dependent_HBX_ID
        Dependent_First_Name
        Dependent_Last_Name
        Previous_Dependent_Relationship
        Current_Dependent_Relationship
        EA_Policy_ID
        Policy_Effective_Date
        Carrier
        Coverage_Type_(health_or_dental)
        Marketplace_(IVL_or_SHOP)
        Date_Relationship_Change_Submitted
        )

      processed_count = 0
      file_name = fetch_file_format('relationship_change_list', 'RELATIONSHIPCHANGELIST')

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        people.no_timeout.each do |person|
          begin
            person.person_relationships.where(updated_at: date_range).each do |person_relationship|
              relationship_history = person_relationship.history_tracks.where(action: 'update').sort_by(&:created_at).last
              next unless relationship_history.present?
              next unless person.primary_family.present?
              enrollments = person.primary_family.hbx_enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
              next unless enrollments.present?
              enrollments.each do |enrollment|
                relationship_changed_member = enrollment.hbx_enrollment_members.select{ |member| member.person.id == person_relationship.relative_id}.first
                next unless relationship_changed_member.present?
                csv << [
                  enrollment.subscriber.hbx_id,
                  enrollment.subscriber.person.first_name,
                  enrollment.subscriber.person.last_name,
                  relationship_changed_member.person.hbx_id,
                  relationship_changed_member.person.first_name,
                  relationship_changed_member.person.last_name,
                  relationship_history.original["kind"],
                  relationship_history.modified["kind"],
                  enrollment.hbx_id,
                  enrollment.effective_on,
                  enrollment.product.issuer_profile.legal_name,
                  enrollment.coverage_kind,
                  enrollment.kind,
                  relationship_history.created_at
                ]
              end
            end
          rescue Exception => e
            "Exception on #{person.hbx_id}: #{e}"
          end
          processed_count += 1
        end
      end
      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} relationship change records found and file outputed to: #{file_name}"
    end
  end
end
