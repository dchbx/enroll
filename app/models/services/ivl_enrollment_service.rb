module Services
  class IvlEnrollmentService

    def initialize
      @logger = Logger.new("#{Rails.root}/log/family_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end

    def process_enrollments(new_date)
      expire_individual_market_enrollments
      begin_coverage_for_ivl_enrollments
      send_enrollment_notice_for_ivl(new_date)
      send_reminder_notices_for_ivl(new_date)
    end

    def expire_individual_market_enrollments
      @logger.info "Started expire_individual_market_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
      current_benefit_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      individual_market_enrollments = HbxEnrollment.where(
        :effective_on.lt => current_benefit_period.start_on,
        :kind.in => ['individual', 'coverall'],
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending']
      )
      individual_market_enrollments.each do |enrollment|
        enrollment.expire_coverage! if enrollment.may_expire_coverage?
        @logger.info "Processed enrollment: #{enrollment.hbx_id}"
      rescue Exception => e
        begin
          family = enrollment.family
          Rails.logger.error "Unable to expire enrollments for family #{family.id}"
          @logger.info "Unable to expire enrollments for family #{family.id}, error: #{e.backtrace}"
        rescue StandardError => e
          @logger.info "Unable to find family for enrollment#{enrollment.id}, error: #{e.backtrace}"
        end
      end
      @logger.info "Ended expire_individual_market_enrollments process at #{TimeKeeper.datetime_of_record}"
    end

    def begin_coverage_for_ivl_enrollments
      @logger.info "Started begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
      current_benefit_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      ivl_enrollments = HbxEnrollment.where(
        :effective_on => current_benefit_period.start_on,
        :kind.in => ['individual', 'coverall'],
        :aasm_state.in => ['auto_renewing', 'renewing_coverage_selected']
      )
      @logger.info "Total IVL auto renewing enrollment count: #{ivl_enrollments.count}"
      count = 0
      ivl_enrollments.no_timeout.each do |enrollment|
        if enrollment.may_begin_coverage?
          enrollment.begin_coverage!
          count += 1
          @logger.info "Processed enrollment: #{enrollment.hbx_id}"
        end
      rescue Exception => e
        begin
          family = enrollment.family
          Rails.logger.error "Unable to begin coverage(enrollments) for family #{family.id}, error: #{e.backtrace}"
          @logger.info "Unable to begin coverage(enrollments) for family #{family.id}, error: #{e.backtrace}"
        rescue StandardError => e
          @logger.info "Unable to find family for enrollment #{enrollment.id}, error: #{e.backtrace}"
        end
      end
      @logger.info "Total IVL auto renewing enrollment processed count: #{count}"
      @logger.info "Ended begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
    end

    def enrollment_notice_for_ivl_families(new_date)
      start_time = (new_date - 2.days).in_time_zone("Eastern Time (US & Canada)").beginning_of_day
      end_time = (new_date - 2.days).in_time_zone("Eastern Time (US & Canada)").end_of_day
      Family.where(
        :"_id".in => HbxEnrollment.where(
          kind: "individual",
          :"aasm_state".in => HbxEnrollment::ENROLLED_STATUSES,
          created_at: { "$gte" => start_time, "$lte" => end_time}
        ).pluck(:family_id)
      )
    end

    def send_enrollment_notice_for_ivl(new_date)
      families = enrollment_notice_for_ivl_families(new_date)
      families.each do |family|
        begin
          person = family.primary_applicant.person
          IvlNoticesNotifierJob.perform_later(person.id.to_s, "enrollment_notice") if person.consumer_role.present?
        rescue Exception => e
          Rails.logger.error { "Unable to deliver enrollment notice #{person.hbx_id} due to #{e.inspect}" }
        end
      end
    end

    def send_reminder_notices_for_ivl(date)
      families = Family.outstanding_verification_datatable
      return if families.blank?

      @logger.info '*' * 50
      @logger.info "Started send_reminder_notices_for_ivl process at #{TimeKeeper.datetime_of_record}"

      families.each do |family|
        begin
          next if family.has_valid_e_case_id? #skip assisted families
          consumer_role = family.primary_applicant.person.consumer_role
          person = family.primary_applicant.person
          if consumer_role.present? && family.best_verification_due_date.present? && (family.best_verification_due_date > date)
            case (family.best_verification_due_date.to_date.mjd - date.mjd)
            when 85
              IvlNoticesNotifierJob.perform_later(person.id.to_s, "first_verifications_reminder")
              @logger.info "Sent first_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
            when 70
              IvlNoticesNotifierJob.perform_later(person.id.to_s, "second_verifications_reminder")
              @logger.info "Sent second_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
            when 45
              IvlNoticesNotifierJob.perform_later(person.id.to_s, "third_verifications_reminder")
              @logger.info "Sent third_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
            when 30
              IvlNoticesNotifierJob.perform_later(person.id.to_s, "fourth_verifications_reminder")
              @logger.info "Sent fourth_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
            end
          end
        rescue StandardError => e
          @logger.info "Unable to send verification reminder notices to #{person.hbx_id} due to #{e}"
        end
        @logger.info "End of generating reminder notices at #{TimeKeeper.datetime_of_record}"
      end
    end
  end
end
