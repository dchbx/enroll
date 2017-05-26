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
     
    def query_criteria
      {
        :kind => 'individual',
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
        :coverage_kind.in => HbxEnrollment::COVERAGE_KINDS
        # :effective_on.gte => HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.start_on
      }
    end

    def families
      Family.where(:"households.hbx_enrollments" => {:$elemMatch => query_criteria})
    end

    def is_individual_assisted?(enrollment)      
      # reader.all_assisted_individuals.keys

      # enrollment.applied_aptc_amount > 0 || enrollment.elected_premium_credit > 0 || enrollment.applied_premium_credit > 0 || is_csr?(enrollment)
      
      @all_assisted_individuals.include?(enrollment.subscriber.hbx_id)
    end

    def is_csr?(enrollment)
      csr_plan_variants = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.except('csr_100').values
      (enrollment.plan.metal_level == "silver") && (csr_plan_variants.include?(enrollment.plan.csr_variant_id))
    end

    # def eligible_to_get_assistance?(enrollment)
    #   if @assisted_individuals[enrollment.subscriber.hbx_id]
    #   end
    # end

    def can_renew_enrollment?(enrollment, family, renewal_benefit_coverage_period)
      enrollments = family.active_household.hbx_enrollments.where({
        :coverage_kind => enrollment.coverage_kind,
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + ["auto_renewing", "renewing_coverage_selected"]),
        :effective_on.gte => renewal_benefit_coverage_period.start_on
      })

      enrollments.detect{|e| enrollment.subscriber.hbx_id == e.subscriber.hbx_id }.blank?
    end

    def get_assisted_enrollments
      current_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period

      aptc_reader = Enrollments::IndividualMarket::AssistedIvlAptcReader.new
      aptc_reader.call
      @assisted_individuals = aptc_reader.assisted_individuals

      count  = 0
      @assisted_individuals.each do |hbx_id, aptc_values|
        
        person = Person.by_hbx_id(hbx_id).first
        family = person.primary_family

        next if family.blank?
        next if family.active_household.blank?

        enrollments = family.active_household.hbx_enrollments.where({
          :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES,
          :kind => 'individual',
          :coverage_kind => 'health'
          }).order(:"effective_on".desc).select{|en| current_benefit_coverage_period.contains?(en.effective_on)}

        enrollment = enrollments.detect{|e| e.subscriber.present? && (e.subscriber.hbx_id == person.hbx_id)}

        if enrollment.present?
          if can_renew_enrollment?(enrollment, family, renewal_benefit_coverage_period)
            count += 1    
            puts "#{enrollment.hbx_id}--#{enrollment.kind}--#{enrollment.aasm_state}--#{enrollment.coverage_kind}--#{enrollment.effective_on}--#{enrollment.plan.renewal_plan.try(:active_year)}"

            enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = enrollment
            enrollment_renewal.assisted = true
            enrollment_renewal.aptc_values = aptc_values
            enrollment_renewal.renewal_benefit_coverage_period = renewal_benefit_coverage_period
            enrollment_renewal.renew
          end
        end
      end
      puts count
    end

    def process
      current_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period

      aptc_reader = Enrollments::IndividualMarket::AssistedIvlAptcReader.new
      aptc_reader.all_hbx_ids
      @all_assisted_individuals = aptc_reader.all_assisted_individuals.keys

      count = 0
      families.each do |family|
        begin
          enrollments = family.active_household.hbx_enrollments.where(query_criteria).order(:"effective_on".desc)
          enrollments = enrollments.select{|en| current_benefit_coverage_period.contains?(en.effective_on)}
          enrollments.each do |enrollment|

            next if is_individual_assisted?(enrollment)
       
            if can_renew_enrollment?(enrollment, family, renewal_benefit_coverage_period)
              count += 1

              if count % 100 == 0
                puts "Found #{count} enrollments"
              end

              puts "#{enrollment.hbx_id}--#{enrollment.kind}--#{enrollment.aasm_state}--#{enrollment.coverage_kind}--#{enrollment.effective_on}--#{enrollment.plan.renewal_plan.try(:active_year)}"

              enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
              enrollment_renewal.enrollment = enrollment
              enrollment_renewal.renewal_benefit_coverage_period = renewal_benefit_coverage_period
              enrollment_renewal.renew
            end
          end
        rescue Exception => e 
          @logger.info "Failed #{family.e_case_id} Exception: #{e.inspect}"
        end
      end
      puts count
    end


    def process_enrollment_renewal(enrollment, renewal_benefit_coverage_period)
      puts "#{enrollment.hbx_id}--#{enrollment.kind}--#{enrollment.aasm_state}--#{enrollment.coverage_kind}--#{enrollment.effective_on}--#{enrollment.plan.renewal_plan.try(:active_year)}"

      enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
      enrollment_renewal.enrollment = enrollment
      enrollment_renewal.renewal_benefit_coverage_period = renewal_benefit_coverage_period
      enrollment_renewal.renew
    end

    def active_enrollment_from_family(enrollment)
      enrollment.family.active_household.hbx_enrollments.where({
        :kind => 'individual',
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing'] - ["coverage_renewed", "coverage_termination_pending"]),
        :coverage_kind => enrollment.coverage_kind
      })
    end

    def process_missing_enrollments
      count = 0

      CSV.open("#{Rails.root}/IVL_Enrollment_Renewals.csv", "w") do |csv|

        csv << ["Enrollment HBX ID", "Subscriber HBX ID", "SSN", "Last Name", "First Name", "HIOS_ID:PlanName", "Other Effective On",  
          "Effective On",  "AASM State",  "Terminated On Action",  "Section:Attribute", "Result"]

        current_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
        renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period

        CSV.foreach("#{Rails.root}/individual_enrollment_change_sets_12_05_2016_10_35.csv", headers: true, :encoding => 'utf-8') do |row|
          count += 1

          if count % 100 == 0
            puts "Found #{count} enrollments"
          end

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

        puts count
      end
    end

    def has_catastrophic_plan?(enrollment)
      enrollment.plan.metal_level == 'catastrophic'       
    end

    def process_from_sheet
      count = 0

      CSV.open("#{Rails.root}/IVL_Enrollment_Renewals.csv", "w") do |csv|

        # csv << ["Enrollment HBX ID", "Subscriber HBX ID", "SSN", "Last Name", "First Name", "HIOS_ID:PlanName", "Other Effective On",  
        #   "Effective On",  "AASM State",  "Terminated On Action",  "Section:Attribute"]


        csv << ["Enrollment HBX ID", "Subscriber HBXID",  "Subscriber Firstname",  "Subscriber Lastname", "Market", "Coverage Kind", "Coverage Start Date", "Created At", "Updated At", "Plan Name", "Plan HIOS ID",  "Enrollment Status"]

        renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period

        CSV.foreach("#{Rails.root}/individuals_missing_passive_renewals.csv", headers: true, :encoding => 'utf-8') do |row|
          count += 1

          if count % 100 == 0
            puts "Found #{count} enrollments"
          end

          hbx_enrollment = HbxEnrollment.by_hbx_id(row.to_hash["Enrollment HBXID"]).first

          status = if hbx_enrollment.blank?
            count += 1
            ["Renewal Failed: Unable to find matching enrollment."]
          elsif !HbxEnrollment::ENROLLED_STATUSES.include?(hbx_enrollment.aasm_state.to_s)
            ["Renewal Failed: Enrollment in #{hbx_enrollment.aasm_state} state."]
          elsif has_catastrophic_plan?(hbx_enrollment)
            ["Renewal Failed: Catastrophic plan found."]
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
