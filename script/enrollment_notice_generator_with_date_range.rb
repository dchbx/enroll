@logger = Logger.new("#{Rails.root}/log/enrollment_notice_data_set.log")
@logger.info "Script Start #{TimeKeeper.datetime_of_record}"

@end_date = Date.new(2017, 12, 20)
@start_date = Date.new(2017, 11, 1)

event_name = "enrollment_notice_with_date_range"

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name
        hbx_enrollment_hbx_ids
      )

report_name = "#{Rails.root}/enrollment_notice_data_set.csv"

def valid_enrollment_hbx_ids(family)
  enrollments = family.enrollments
  good_enrollments = enrollments.where(kind: "individual").enrolled.by_submitted_datetime_range(@start_date, @end_date)
  auto_renewing_enrollments = enrollments.where(kind: "individual").renewing.by_submitted_datetime_range(@start_date, @end_date)
  bad_enrollments_fre = enrollments.where(kind: "individual").enrolled.by_submitted_datetime_range(Date.new(2017, 1, 1), @start_date - 1.days)
  has_renewals = good_enrollments.any?{ |hbx_enr| hbx_enr.was_in_renewal_status? } ? true : false
  future_enrollments = enrollments.enrolled.where(kind: "individual").any? { |enr| enr.submitted_at.present? && (enr.submitted_at.to_date > @end_date) }

  good_enrollments.uniq!

  if !bad_enrollments_fre.present? && !has_renewals && !auto_renewing_enrollments.present? && !future_enrollments.present?
    return good_enrollments.map(&:hbx_id)
  else
    return []
  end
end

families = Family.where({
  "households.hbx_enrollments" => {
    "$elemMatch" => {
      "kind" => "individual",
      "submitted_at" => {:"$gte" => @start_date, :"$lte" => @end_date},
      "aasm_state" => { "$in" =>  HbxEnrollment::ENROLLED_STATUSES },
      "effective_on" => Date.new(2018, 1, 1)
    }
  }
})

total_families = families.count
offset_count = 0
limit_count = 500
processed_count = 0

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while (offset_count <= total_families) do
    families.offset(offset_count).limit(limit_count).each do |family|
      begin
        person = family.primary_applicant.person

        hbx_enrollment_hbx_ids = valid_enrollment_hbx_ids(family)
        hbx_enrollment_hbx_ids.compact!
        role = person.consumer_role

        if role.present? && hbx_enrollment_hbx_ids.present?

          event_kind = ApplicationEventKind.where(:event_name => event_name).first
          notice_trigger = event_kind.notice_triggers.first
          builder = notice_trigger.notice_builder.camelize.constantize.new(role, {
                    template: notice_trigger.notice_template,
                    subject: event_kind.title,
                    event_name: event_name,
                    options: {:hbx_enrollment_hbx_ids => hbx_enrollment_hbx_ids },
                    mpi_indicator: notice_trigger.mpi_indicator,
                    }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
          processed_count = processed_count + 1
          @logger.info "#{event_name} generated to family with primary_person: #{person.hbx_id}" unless Rails.env.test?

          csv << [
            person.hbx_id,
            person.first_name,
            person.last_name,
            hbx_enrollment_hbx_ids
          ]
        end
      rescue Exception => e
        @logger.error "Unable to deliver #{event_name} to family with PrimaryPerson: #{person.hbx_id} due to the following error #{e.backtrace}" unless Rails.env.test?
      end
    end
    @logger.info " #{offset_count} number of families processed at this point." unless Rails.env.test?
    offset_count = offset_count + limit_count
  end
  @logger.info "End of the script. #{processed_count} number of families processed." unless Rails.env.test?
end
