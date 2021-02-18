require File.join(Rails.root, "lib/mongoid_migration_task")

# frozen_string_literal: true
class ForcePublishBenAppReports < MongoidMigrationTask

  def migrate
    start_on_date = Date.strptime(ENV['start_on_date'].to_s, "%m/%d/%Y")
    current_date = Date.strptime(ENV['current_date'].to_s, "%m/%d/%Y")
    if ENV['only_assign_packages'] == "true"
      puts 'Assigning packages and creating unassigned packages csv...'
      assign_packages(start_on_date, current_date)
    elsif ENV['reports_only'] == "true"
      puts 'Creating detail and non-detail report...'
      detailed_report(start_on_date, current_date)
      non_detailed_report(start_on_date, current_date)
    elsif ENV['detailed_report_only'] == "true"
      puts 'Creating detail report...'
      detailed_report(start_on_date, current_date)
    elsif ENV['query_count_only'] == "true"
      puts "Enrollment count is #{query_enrollment_count(start_on_date, current_date)}"
    else
      force_publishing_process(start_on_date, current_date)
    end
  end

  def force_publishing_process(start_on_date, current_date)
    puts 'Reverting plan years...' unless Rails.env.test?
    revert_benefit_applications(start_on_date, current_date) # setting renewing published plan years back to renewing draft
    puts 'Assigning packages...' unless Rails.env.test?
    assign_packages(start_on_date, current_date) #assign benefit packages to census employeess missing them
    puts 'Setting back oe dates...' unless Rails.env.test?
    set_back_oe_date(start_on_date, current_date) #set back oe dates for renewing draft employers with OE dates greater than current date
    puts 'Force Publishing...' unless Rails.env.test?
    force_publish(start_on_date, current_date) # force publish
    puts 'Generating error CSV of ERs with Benefit Applications not in Renewing Enrolling for some reason... ' unless Rails.env.test?
    ben_app_not_in_oe(start_on_date, current_date) #create error csv file with ERs that did not transition correctly
    completion_check(start_on_date, current_date)  unless Rails.env.test?
  end

  def benefit_applications_in_aasm_state(aasm_states, start_on_date)
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
      {:benefit_applications =>
        { :$elemMatch => {
          :"effective_period.min" => start_on_date,
          :predecessor_id => {"$ne" => nil},
          :aasm_state.in => aasm_states
        }}}
    )
  end

  def revert_benefit_applications(start_on_date, _current_date)
    puts "----renewing published count == #{benefit_applications_in_aasm_state(['pending'], start_on_date).count} prior to reverting----" unless Rails.env.test?
    benefit_applications_in_aasm_state(['pending'], start_on_date).each do |ben_spon|
      ben_app = ben_spon.renewal_benefit_application
      ben_app.revert_application! if ben_app.may_revert_application?
    end
    puts "----renewing published count == #{benefit_applications_in_aasm_state(['pending'], start_on_date).count} after reverting----" unless Rails.env.test?
    puts "----renewing draft count == #{benefit_applications_in_aasm_state(['draft'], start_on_date).count} after reverting plan years" unless Rails.env.test?
  end

  def assign_packages(start_on_date, _current_date)
    file_name = "#{Rails.root}/unnassigned_packages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
    system("rm -rf #{file_name}")
    CSV.open(file_name, "w") do |csv|
      csv << ["Sponsor fein", "Sponsor legal_name", "Census_Employee", "ce id"]
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min' => start_on_date).each do |ben_spon|
        ben_spon.benefit_applications.each do |bene_app|
          next unless bene_app.effective_period.min == start_on_date && bene_app.is_renewing?

          ben_spon.census_employees.active.each do |census|
            next if census.employee_role.blank?
            next if census.benefit_group_assignments.where(:benefit_package_id.in => bene_app.benefit_packages.map(&:id)).blank?
            next unless ["employment_terminated","rehired","cobra_terminated"].include?(census.aasm_state)
            data = [ben_spon.fein, ben_spon.legal_name, census.full_name, census.id]
            csv << data
            census.try(:save!)
          end
        end
        puts "#{ben_spon.fein} has errors #{ben_spon.errors}" unless Rails.env.test? || ben_spon.errors.blank?
      end
      puts "Unnasigned packages file created #{file_name}" unless Rails.env.test?
    end
  end

  def set_back_oe_date(start_on_date, current_date)
    puts "Setting back OE dates for the below ERs" unless Rails.env.test?
    benefit_applications_in_aasm_state(['draft'], start_on_date).each do |ben_spon|
      ben_app = ben_spon.renewal_benefit_application
      next unless ben_app.open_enrollment_period.min > current_date

      puts ben_spon.fein.to_s unless Rails.env.test?
      oe_max = ben_app.open_enrollment_period.max
      ben_app.update_attributes!(open_enrollment_period: current_date..oe_max)
      ben_app.save!
    end
  end

  def force_publish(start_on_date, _current_date)
    puts "----Renewing draft count == #{benefit_applications_in_aasm_state(['draft'], start_on_date).count} prior to publish" unless Rails.env.test?
    benefit_applications_in_aasm_state(['draft'], start_on_date).each do |ben_spon|
      ben_app = ben_spon.renewal_benefit_application
      ben_app.simulate_provisional_renewal! if ben_app.may_simulate_provisional_renewal?
    end
    puts "----Renewing draft count == #{benefit_applications_in_aasm_state(['draft'], start_on_date).count} after publish" unless Rails.env.test?
    puts "----Renewing enrolling count == #{benefit_applications_in_aasm_state(['enrollment_open'], start_on_date).count} after publish" unless Rails.env.test?
  end

  def ben_app_not_in_oe(start_on_date, _current_date)
    CSV.open("#{Rails.root}/employers_not_in_renewing_enrolling_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv", "w") do |csv|
      csv << ["Organization name","Organization fein","Benefit Application State"]
      benefit_applications_in_aasm_state(['draft','pending','enrollment_eligible','approved','active','termination_pending','canceled','enrollment_ineligible','enrollment_extended'], start_on_date).each do |ben_spon|
        aasm_state = ben_spon.renewal_benefit_application&.aasm_state
        data = [ben_spon.legal_name, ben_spon.fein, aasm_state]
        csv << data
      end
    end
  end

  def query_enrollment_count(start_on_date, _current_date)
    feins = benefit_applications_in_aasm_state(['enrollment_open'], start_on_date).inject([]) do |fein,ben_spon|
      fein << ben_spon.fein
    end
    clean_feins = feins.map do |f|
      f.gsub(/\D/,"")
    end
    qs = Queries::PolicyAggregationPipeline.new
    qs.filter_to_shop.filter_to_active.filter_to_employers_feins(clean_feins).with_effective_date({"$gt" => (start_on_date - 1.day)}).eliminate_family_duplicates
    enroll_pol_ids = []
    qs.evaluate.each do |r|
      enroll_pol_ids << r['hbx_id']
    end
    enroll_pol_ids.count
  end

  def completion_check(start_on_date, current_date)
    loop do
      before = query_enrollment_count(start_on_date, current_date)
      puts " before = #{before}"  unless Rails.env.test?
      sleep 60
      after = query_enrollment_count(start_on_date, current_date)
      puts " after = #{after}"  unless Rails.env.test?
      if before == after
        puts 'Renewals complete'  unless Rails.env.test?
        return
      end
    end
  end
 
  def non_detail_active_bg_ids(active_bg_ids)
    active_enrollment_count = 0
    enrollments = HbxEnrollment.where({
                                        :sponsored_benefit_package_id.in => active_bg_ids,
                                        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
                                      })
    %w[health dental].each do |coverage_kind|
      active_enrollment_count += enrollments.where(:coverage_kind => coverage_kind).count if enrollments.where(:coverage_kind => coverage_kind).present?
    end
    active_enrollment_count
  end

  def non_detail_renewal_bg_ids(renewal_bg_ids)
    renewal_enrollment_count = 0
    renewal_enrollments = HbxEnrollment.where({
                                                :sponsored_benefit_package_id.in => renewal_bg_ids,
                                                :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']
                                              })

    %w[health dental].each do |coverage_kind|
      renewal_enrollment_count += renewal_enrollments.where(:coverage_kind => coverage_kind).count if renewal_enrollments.where(:coverage_kind => coverage_kind).present?
    end
    renewal_enrollment_count
  end

  def non_detailed_report(start_on_date, _current_date)
    file_name = "#{Rails.root}/dry_run_dc_nfp_non_detailed_report_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
    field_names = [
      "Employer_Legal_Name",
      "Employer_FEIN",
      "Renewal State",
      "#{start_on_date.prev_year.year} Active Enrollments",
      "#{start_on_date.prev_year.year} Passive Renewal Enrollments"
    ]
    system("rm -rf #{file_name}")

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min' => start_on_date).each do |ben_spon|
        ben_spon.benefit_applications.each do |ben_app|
          next unless ben_app.effective_period.min == start_on_date && ben_app.is_renewing?

          data =  [ben_spon.legal_name, ben_spon.fein, ben_spon.renewal_benefit_application.aasm_state.to_s.camelcase]
          next if ben_spon.renewal_benefit_application.blank?

          active_bg_ids = ben_spon.current_benefit_application.benefit_packages.pluck(:id)

          renewal_bg_ids = ben_spon.renewal_benefit_application.benefit_packages.pluck(:id) if ben_spon.renewal_benefit_application.present?
          active_enrollment_count = non_detail_active_bg_ids(active_bg_ids) if active_bg_ids.present?
          renewal_enrollment_count = non_detail_renewal_bg_ids(renewal_bg_ids) if renewal_bg_ids.present?
          data += [active_enrollment_count, renewal_enrollment_count]
          csv << data
        end
      end
    end
  end

  def detailed_report_field_names(start_on_date)
    [
      "Employer Legal Name",
      "Employer FEIN",
      "Employer HBX ID",
      "#{start_on_date.prev_year.year} effective_date",
      "#{start_on_date.prev_year.year} State",
      "#{start_on_date.year} effective_date",
      "#{start_on_date.year} State",
      "First name",
      "Last Name",
      "Roster status",
      "Hbx ID",
      "#{start_on_date.prev_year.year} enrollment",
      "#{start_on_date.prev_year.year} enrollment kind",
      "#{start_on_date.prev_year.year} plan",
      "#{start_on_date.prev_year.year} effective_date",
      "#{start_on_date.prev_year.year} status",
      "#{start_on_date.year} enrollment",
      "#{start_on_date.year} enrollment kind",
      "#{start_on_date.year} plan",
      "#{start_on_date.year} effective_date",
      "#{start_on_date.year} status",
      "Reasons"
    ]
  end

  def detailed_report(start_on_date, _current_date)
    file_name = "#{Rails.root}/dry_run_dc_nfp_detailed_report_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"

    system("rm -rf #{file_name}")

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << detailed_report_field_names(start_on_date)
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min' => start_on_date).no_timeout.each do |ben_spon|
        ben_spon.benefit_applications.each do |ben_app|

          next unless ben_app.effective_period.min == start_on_date && ben_app.is_renewing?

          ben_app_prev_year = ben_spon.benefit_applications.where(:"effective_period.min".lt => start_on_date, aasm_state: :active).first
          ben_spon.census_employees.active.each do |census|
            if census.employee_role.present?
              family = census.employee_role.person.primary_family
            elsif Person.by_ssn(census.ssn).present? && Person.by_ssn(census.ssn).employee_roles.select{|e| e.census_employee_id == census.id && e.is_active == true}.present?
              person = Person.by_ssn(census.ssn).first
              family = person.primary_family
            end
            if family.present?
              ben_app_prev_year = ben_spon.benefit_applications.where(:"effective_period.min".lt => start_on_date, aasm_state: :active).first
              packages_prev_year = ben_app_prev_year.present? ? ben_app_prev_year.benefit_packages.map(&:id) : []
              package_ids = packages_prev_year + ben_app.benefit_packages.map(&:id)
              enrollments = family.active_household.hbx_enrollments.where(:sponsored_benefit_package_id.in => package_ids, :aasm_state.nin => ["shopping", "coverage_canceled", "coverage_expired"])
            end

            next unless enrollments

            ["health", "dental"].each do |kind|
              enrollment_prev_year = enrollments.where(coverage_kind: kind, :effective_on.lt => start_on_date).last
              enrollment_current_year = enrollments.where(coverage_kind: kind, :effective_on => start_on_date).first
              next unless enrollment_prev_year || enrollment_current_year

              data = [ben_spon.profile.legal_name,
                      ben_spon.profile.fein,
                      ben_spon.profile.hbx_id,
                      ben_app_prev_year.try(:effective_period).try(:min),
                      ben_app_prev_year.try(:aasm_state),
                      ben_app.effective_period.min,
                      "renewing_#{ben_app.aasm_state}",
                      census.first_name,
                      census.last_name,
                      census.aasm_state,
                      census.try(:employee_role).try(:person).try(:hbx_id) || Person.by_ssn(census.ssn).first.hbx_id,
                      enrollment_prev_year.try(:hbx_id),
                      enrollment_prev_year.try(:coverage_kind),
                      enrollment_prev_year.try(:product).try(:hios_id),
                      enrollment_prev_year.try(:effective_on),
                      enrollment_prev_year.try(:aasm_state),
                      enrollment_current_year.try(:hbx_id),
                      enrollment_prev_year.try(:coverage_kind),
                      enrollment_current_year.try(:product).try(:hios_id),
                      enrollment_current_year.try(:effective_on),
                      enrollment_current_year.try(:aasm_state)]
              data += [find_failure_reason(enrollment_prev_year, enrollment_current_year, ben_app)]
              csv << data
            end
          end
        end
      end
    end
  end

  def find_failure_reason(enrollment_prev_year, enrollment_current_year, ben_app)
    current_year_state = enrollment_current_year.try(:aasm_state)
    prev_year_state = enrollment_prev_year.try(:aasm_state)
    rp_id = enrollment_prev_year.try(:product).try(:renewal_product_id)
    cp_id = enrollment_current_year.try(:product).try(:id)

    if current_year_state == 'auto_renewing'
      "Successfully Generated"
    elsif current_year_state == 'coverage_enrolled'
      "The plan year was manually published by stakeholders" if ["active","enrollment_eligible"].include?(ben_app.aasm_state)
    elsif current_year_state == "coverage_selected"
      "Plan was manually selected for the current year" unless rp_id == cp_id
    elsif ["inactive","renewing_waived"].include?(current_year_state)
      "enrollment is waived"
    elsif current_year_state.nil? && ben_app.aasm_state == 'pending'
      "ER zip code is not in DC"
    elsif current_year_state.nil? && prev_year_state.in?(HbxEnrollment::WAIVED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
      "Previous plan has waived or terminated and did not generate renewal"
    elsif current_year_state.nil? && ["coverage_selected", "coverage_enrolled"].include?(prev_year_state)
      "Enrollment plan was changed either for current year or previous year" unless rp_id == cp_id
    else
      return ''
    end
  end
end