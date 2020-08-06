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
    aptc_reader = Enrollments::IndividualMarket::AssistedIvlAptcReader.new
    aptc_reader.calender_year = renewal_benefit_coverage_period.start_on.year
    aptc_reader.call
    @assisted_individuals = aptc_reader.assisted_individuals
    puts "Found #{@assisted_individuals.keys.count} entries in Assisted sheet." unless Rails.env.test?

    process_aqhp_renewals(renewal_benefit_coverage_period)
    process_uqhp_renewals(renewal_benefit_coverage_period)
    @logger.info "Process ended at #{Time.now.in_time_zone("Eastern Time (US & Canada)").strftime("%m-%d-%Y %H:%M")}"
  end

  def is_individual_assisted?(enrollment)
    # reader.all_assisted_individuals.keys
    # enrollment.applied_aptc_amount > 0 || enrollment.elected_premium_credit > 0 || enrollment.applied_premium_credit > 0 || is_csr?(enrollment)

    @all_assisted_individuals.include?(enrollment.subscriber.hbx_id)
  end

  def is_csr?(enrollment)
    csr_product_variants = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.except('csr_0').values
    (enrollment.product.metal_level == :silver) && csr_product_variants.include?(enrollment.product.csr_variant_id)
  end

  # def eligible_to_get_assistance?(enrollment)
  #   if @assisted_individuals[enrollment.subscriber.hbx_id]
  #   end
  # end

  def kollection(kind, coverage_period)
    {
      :kind.in => ['individual', 'coverall'],
      :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
      :coverage_kind.in => kind,
      :effective_on => { "$gte" => coverage_period.start_on, "$lt" => coverage_period.end_on}
    }
  end

  def process_aqhp_renewals(renewal_benefit_coverage_period)
    puts "Assisted Renewing Started..." unless Rails.env.test?
    current_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
    query = kollection(["health"], current_benefit_coverage_period)
    count = 0
    @assisted_individuals.each do |hbx_id, aptc_values|
      person = Person.by_hbx_id(hbx_id).first
      family = person.primary_family

      next if family.blank?
      next if family.active_household.blank?

      puts "Processing #{person.full_name}(#{person.hbx_id})" unless Rails.env.test?

      active_household = family.active_household
      coverage_period_tax_household = active_household.latest_active_thh_with_year(renewal_benefit_coverage_period.start_on.year)

      enrollments = active_household.hbx_enrollments.where(query).order(:"effective_on".desc)
      enrollments = enrollments.select{|e| e.subscriber.present? && (e.subscriber.hbx_id == person.hbx_id)}

      if enrollments.size > 1
        @logger.info "Found multiple active health enrollments for Person: #{hbx_id}"
        next
      end

      if enrollments.present?
        if enrollments.first.can_renew_coverage?(renewal_benefit_coverage_period.start_on)
          count += 1
          result = ::Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: enrollments.first,
                                                                      effective_on: renewal_benefit_coverage_period.start_on,
                                                                      aptc_values: aptc_values)
          result.failure? ? result.failure : result.success
        end
      else
        @logger.info "Unable to find valid assisted enrollment for Person: #{hbx_id}"
      end
    end

    puts "Total assisted renewal processed #{count}" unless Rails.env.test?
  end

  def process_uqhp_renewals(renewal_benefit_coverage_period)
    puts("*" * 60) unless Rails.env.test?
    puts "Un-Assisted Renewing Started..." unless Rails.env.test?
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
          next if @assisted_individuals.key?(primary_hbx_id) && enrollment.coverage_kind == 'health'

          next unless enrollment.can_renew_coverage?(renewal_benefit_coverage_period.start_on)

          count += 1
          @logger.info "Found #{count} enrollments" if count % 100 == 0

          # puts "#{enrollment.hbx_id}--#{enrollment.kind}--#{enrollment.aasm_state}--#{enrollment.coverage_kind}--#{enrollment.effective_on}--#{enrollment.product.renewal_product.try(:active_year)}"
          result = ::Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: enrollment,
                                                                      effective_on: renewal_benefit_coverage_period.start_on,
                                                                      aptc_values: {})
          result.failure? ? result.failure : result.success
        end
      rescue Exception => e
        @logger.info "Failed ECaseId: #{family.e_case_id} Primary: #{primary_hbx_id} Exception: #{e.inspect}"
      end
    end
    puts "Total unassisted renewal processed #{count}" unless Rails.env.test?
  end

  def process_enrollment_renewal(enrollment, renewal_benefit_coverage_period)
    puts "#{enrollment.hbx_id}--#{enrollment.kind}--#{enrollment.aasm_state}--#{enrollment.coverage_kind}--#{enrollment.effective_on}--#{enrollment.product.renewal_product.try(:active_year)}"

    enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
    enrollment_renewal.enrollment = enrollment
    enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
    enrollment_renewal.renew
  end

  def active_enrollment_from_family(enrollment)
    enrollment.family.active_household.hbx_enrollments.where(
      {:kind.in => ['individual', 'coverall'],
       :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing'] - ["coverage_renewed", "coverage_termination_pending"]),
       :coverage_kind => enrollment.coverage_kind}
    )
  end

  def process_missing_enrollments
    count = 0

    CSV.open("#{Rails.root}/IVL_Enrollment_Renewals.csv", "w") do |csv|

      csv << ["Enrollment HBX ID", "Subscriber HBX ID", "SSN", "Last Name", "First Name",
              "HIOS_ID:ProductName", "Other Effective On", "Effective On",  "AASM State",
              "Terminated On Action",  "Section:Attribute", "Result"]

      current_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period

      CSV.foreach("#{Rails.root}/individual_enrollment_change_sets_12_05_2016_10_35.csv", headers: true, :encoding => 'utf-8') do |row|
        count += 1
        puts "Found #{count} enrollments" if count % 100 == 0

        enrollment = HbxEnrollment.by_hbx_id(row.to_hash["Enrollment HBX ID"]).first

        hbx_enrollments = active_enrollment_from_family(enrollment).reject{|en| en.subscriber.present? && enrollment.subscriber.present? && en.subscriber.hbx_id != enrollment.subscriber.hbx_id }

        current_coverages = hbx_enrollments.select{|en| current_benefit_coverage_period.contains?(en.effective_on) }
        renewal_coverages = hbx_enrollments.select{|en| renewal_benefit_coverage_period.contains?(en.effective_on) }

        status = if current_coverages.blank?
                   ["Renewal Failed: Unable to find matching enrollment."]
                 elsif current_coverages.size > 1
                   ["Renewal Failed: found multiple active enrollments."]
                 elsif renewal_coverages.present?
                   en = renewal_coverages.first
                   ["Renewal Failed: Already got #{en.effective_on.year} coverage with #{en.aasm_state.camelcase} status."]
                 elsif is_individual_assisted?(current_coverages.first)
                   ["Renewal Failed: Assisted Enrollment."]
                 else
                   begin
                     process_enrollment_renewal(current_coverages.first, renewal_benefit_coverage_period)
                     ["Renewal Successful."]
                   rescue Exception => e
                     ["Renewal Failed: #{e.tos}."]
                   end
                 end

        csv << (row.to_h.values + status)
      end

      puts count unless Rails.env.test?
    end
  end

  def has_catastrophic_product?(enrollment)
    enrollment.product.metal_level == :catastrophic
  end

  def process_from_sheet
    count = 0

    CSV.open("#{Rails.root}/IVL_Enrollment_Renewals.csv", "w") do |csv|

      # csv << ["Enrollment HBX ID", "Subscriber HBX ID", "SSN", "Last Name", "First Name", "HIOS_ID:ProductName", "Other Effective On",
      #   "Effective On",  "AASM State",  "Terminated On Action",  "Section:Attribute"]

      csv << ["Enrollment HBX ID", "Subscriber HBXID",  "Subscriber Firstname",  "Subscriber Lastname", "Market", "Coverage Kind", "Coverage Start Date", "Created At", "Updated At", "Product Name", "Product HIOS ID",  "Enrollment Status"]

      renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period

      CSV.foreach("#{Rails.root}/individuals_missing_passive_renewals.csv", headers: true, :encoding => 'utf-8') do |row|
        count += 1
        puts "Found #{count} enrollments" if count % 100 == 0

        hbx_enrollment = HbxEnrollment.by_hbx_id(row.to_hash["Enrollment HBXID"]).first

        status = if hbx_enrollment.blank?
                   count += 1
                   ["Renewal Failed: Unable to find matching enrollment."]
                 elsif !HbxEnrollment::ENROLLED_STATUSES.include?(hbx_enrollment.aasm_state.to_s)
                   ["Renewal Failed: Enrollment in #{hbx_enrollment.aasm_state} state."]
                 elsif has_catastrophic_product?(hbx_enrollment)
                   ["Renewal Failed: Catastrophic product found."]
                 elsif is_individual_assisted?(hbx_enrollment)
                   ["Renewal Failed: Assisted Enrollment."]
                 else
                   begin
                     process_enrollment_renewal(hbx_enrollment, renewal_benefit_coverage_period)
                     ["Renewal Successful."]
                   rescue Exception => e
                     ["Renewal Failed: #{e.tos}."]
                   end
                 end

        csv << (row.to_h.values + status)
      end

      puts count
    end
  end
end
