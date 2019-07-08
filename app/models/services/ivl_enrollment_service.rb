module Services
  class IvlEnrollmentService

    def initialize
      @logger = Logger.new("#{Rails.root}/log/family_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end

    def expire_individual_market_enrollments
      @logger.info "Started expire_individual_market_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
      current_benefit_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      individual_market_enrollments = HbxEnrollment.where(
        :effective_on.lt => current_benefit_period.start_on,
        kind: 'individual',
        :"aasm_state".in => HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending', 'enrolled_contingent', 'unverified']
      )
      begin
        individual_market_enrollments.each do |enrollment|
          enrollment.expire_coverage! if enrollment.may_expire_coverage?
          @logger.info "Processed enrollment: #{enrollment.hbx_id}"
        end
      rescue Exception => e
        family = Family.find(individual_market_enrollments.family_id)
        Rails.logger.error "Unable to expire enrollments for family #{family.e_case_id}"
        @logger.info "Unable to expire enrollments for family #{family.id}, error: #{e.backtrace}"
      end
      @logger.info "Ended begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
    end

    def begin_coverage_for_ivl_enrollments
      @logger.info "Started begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
      current_benefit_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      ivl_enrollments = HbxEnrollment.where(
        effective_on: current_benefit_period.start_on,
        kind: 'individual',
        aasm_state: 'auto_renewing'
      )
      begin 
        ivl_enrollments.each do |enrollment|
          enrollment.begin_coverage! if enrollment.may_begin_coverage?
          @logger.info "Processed enrollment: #{enrollment.hbx_id}"
        end
      rescue Exception => e
        family = Family.find(individual_market_enrollments.family_id)
        Rails.logger.error "Unable to begin coverage(enrollments) for family #{family.id}, error: #{e.backtrace}"
        @logger.info "Unable to begin coverage(enrollments) for family #{family.id}, error: #{e.backtrace}"
      end
      @logger.info "Ended begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
    end

    def advance_day(new_date)
      expire_individual_market_enrollments
      begin_coverage_for_ivl_enrollments
      send_enrollment_notice_for_ivl(new_date)
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
  end
end