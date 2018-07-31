date = Date.today

if date.day > 15
  window_start = Date.new(date.year,date.month,16)
  window_end = Date.new(date.next_month.year,date.next_month.month,15)
  window = (window_start..window_end)
elsif date.day <= 15
  window_start = Date.new((date - 1.month).year,(date - 1.month).month,16)
  window_end = Date.new(date.year,date.month,15)
  window = (window_start..window_end)
end

start_on_date = window.end.next_month.beginning_of_month.to_time.utc.beginning_of_day

product_cache = {}

BenefitMarkets::Products::Product.all.each do |product|
  product_cache[product.id] = product
end

def find_renewed_sponsorships(start_date)
  BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
    "benefit_applications" => {
      "$elemMatch" => {
        "effective_period.min" => start_date,
        # "predecessor_id" => {"$ne" => nil},
        "aasm_state" => {"$in" => [
          :enrollment_open,
          :enrollment_closed,
          :enrollment_eligible,
          :active
        ]}
      }
    }
  })
end

def matching_plan_details(enrollment, other_hbx_enrollment, product_cache)
  return false if other_hbx_enrollment.product_id.blank?
  new_plan = product_cache[enrollment.product_id]
  old_plan = product_cache[other_hbx_enrollment.product_id]
  (old_plan.issuer_profile_id == new_plan.issuer_profile_id) &&
    (old_plan.active_year == new_plan.active_year - 1)
end

def initial_or_renewal(enrollment,product_cache,predecessor_id)
  return "initial" if predecessor_id.blank?
  renewal_enrollments = enrollment.family.households.flat_map(&:hbx_enrollments).select{|hbx_enrollment| hbx_enrollment.sponsored_benefit_package_id == predecessor_id}
  reject_statuses = HbxEnrollment::CANCELED_STATUSES + HbxEnrollment::WAIVED_STATUSES + %w(unverified void)
  renewal_enrollments_no_cancels_waives = renewal_enrollments.reject{|ren| reject_statuses.include?(ren.aasm_state.to_s)}
  renewal_enrollments_no_terms = renewal_enrollments_no_cancels_waives.reject{|ren| %w(coverage_terminated coverage_termination_pending).include?(ren.aasm_state.to_s) &&
                                                                                    ren.terminated_on.present? &&
                                                                                    ren.terminated_on < (enrollment.effective_on - 1.day)}
  if renewal_enrollments_no_terms.any?{|ren| matching_plan_details(enrollment,ren,product_cache)}
    return "renewal"
  elsif renewal_enrollments_no_terms.empty?
    return "initial"
  else
    return "initial"
  end
end

renewed_sponsorships = find_renewed_sponsorships(start_on_date)

initial_file = File.open("policies_to_pull_ies.txt","w")
renewal_file = File.open("policies_to_pull_renewals.txt","w")

renewed_sponsorships.each do |bs|
  fein = fein = bs.profile.organization.fein
  selected_application = bs.benefit_applications.detect do |ba|
    (!ba.predecessor_id.blank?) && 
    (ba.start_on == start_on_date) && 
    [:enrollment_open,:enrollment_closed,:enrollment_eligible,:active].include?(ba.aasm_state)
  end

  benefit_packages = selected_application.benefit_packages

  enrollment_ids = []

  benefit_packages.each do |benefit_package|
    employer_enrollment_query = ::Queries::NamedEnrollmentQueries.find_simulated_renewal_enrollments(benefit_package.sponsored_benefits, start_on_date)
    employer_enrollment_query.each{|id| enrollment_ids << id}
  end

  enrollment_ids.each do |enrollment_hbx_id|
    enrollment = HbxEnrollment.by_hbx_id(enrollment_hbx_id).first
    puts "#{enrollment.hbx_id} has no plan" if enrollment.product.blank?
    if initial_or_renewal(enrollment,product_cache,selected_application.benefit_packages.first.predecessor_id) == 'initial'
      initial_file.puts(enrollment_hbx_id)
    elsif initial_or_renewal(enrollment,product_cache,selected_application.benefit_packages.first.predecessor_id) == 'renewal'
      renewal_file.puts(enrollment_hbx_id)
    end
  end
end

initial_file.close
renewal_file.close

