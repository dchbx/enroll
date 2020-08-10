# frozen_string_literal: true

class Enrollments::IndividualMarket::OpenEnrollmentBegin
  # Active IVL hbx enrollments
  # without a termination date in the current year
  # kind 'individual'
  # health || dental
  # effective on >= 1/1/2016
  # terminated_on.blank? || terminated_on > 12/31/2016
  # hbx sponsored benefit
  # Unassisted, Assisted, CSR Assisted, Catastrophic
  # Responsible party
  # :$or => [
  #   :terminated_on.lte => HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.end_on,
  #   :terminated_on => nil
  # ]
  # TODO: Move aged off people from immedidate coverage household to extended coverage household on the day new benefit coverage period begin.

  def initialize
    @logger = Logger.new("#{Rails.root}/log/ivl_open_enrollment_begin_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end

  def process_renewals
    @logger.info "Started process at #{Time.now.in_time_zone("Eastern Time (US & Canada)").strftime("%m-%d-%Y %H:%M")}"
    renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period
    process_qhp_renewals(renewal_benefit_coverage_period)
    @logger.info "Process ended at #{Time.now.in_time_zone("Eastern Time (US & Canada)").strftime("%m-%d-%Y %H:%M")}"
  end

  def kollection(kind, coverage_period)
    {
      :kind.in => ['individual', 'coverall'],
      :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
      :coverage_kind.in => kind,
      :effective_on => { "$gte" => coverage_period.start_on, "$lt" => coverage_period.end_on}
    }
  end

  def process_qhp_renewals(renewal_benefit_coverage_period)
    puts("*" * 60) unless Rails.env.test?
    puts "Renewing Started..." unless Rails.env.test?
    current_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
    query = kollection(HbxEnrollment::COVERAGE_KINDS, current_benefit_coverage_period)
    family_ids = HbxEnrollment.where(query).pluck(:family_id).uniq
    @logger.info "Families count #{family_ids.count}"

    count = 0
    family_ids.each do |family_id|
      family = Family.find(family_id.to_s)
      primary_hbx_id = family.primary_applicant.person.hbx_id

      begin
        enrollments = family.active_household.hbx_enrollments.where(query).order(:"effective_on".desc)
        enrollments = enrollments.select{|en| current_benefit_coverage_period.contains?(en.effective_on)}
        enrollments.each do |enrollment|
          next unless enrollment.can_renew_coverage?(renewal_benefit_coverage_period.start_on)

          count += 1
          @logger.info "Found #{count} enrollments" if count % 100 == 0
          result = ::Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: enrollment,
                                                                      effective_on: renewal_benefit_coverage_period.start_on)
          result.failure? ? result.failure : result.success
        end
      rescue Exception => e
        @logger.info "Failed ECaseId: #{family.e_case_id} Primary: #{primary_hbx_id} Exception: #{e.inspect}"
      end
    end
    puts "Total renewals processed #{count}" unless Rails.env.test?
  end
end
