# Passing an year argument is reauired for this script
# for example
# RAILS_ENV=production bundle exec rails r script/final_eligibility_notice_report_unassisted.rb 2019

puts "-------------------------------------- Start of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
batch_size = 500
offset = 0
current_year = ARGV[0].to_i
enrollment_count = HbxEnrollment.by_year(current_year + 1).individual_market.count

product_ids = BenefitMarkets::Products::Product.by_year(current_year + 1).aca_individual_market.map(&:_id)

csv = CSV.open("final_eligibility_notice_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv << %w(ic_number policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.plan.plan_name policy.total_premium deductible family_deductible  subscriber_id member_id person.first_name person.last_name
        policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status outstanding_verification_types document_due_date
        policy.subscriber.person.is_dc_resident? dependent)


def add_to_csv(csv, policy, person, is_dependent, outstanding_verification_types, document_due_date)
  csv << [policy.family.id, policy.hbx_id, policy.effective_on, policy.aasm_state, policy.product.kind, policy.product.metal_level_kind, policy.product.title, policy.total_premium,
          policy.product.deductible, policy.product.family_deductible.split("|").last.squish,
          person.hbx_id, person.hbx_id, person.first_name, person.last_name,
          person.is_incarcerated, person.citizen_status, outstanding_verification_types, document_due_date,
          is_dc_resident(person)] + [is_dependent]
end

def is_dc_resident(person)
  return false if person.no_dc_address == true && person.no_dc_address_reason.blank?
  return true if person.no_dc_address == true && person.no_dc_address_reason.present?

  address_to_use = person.addresses.collect(&:kind).include?('home') ? 'home' : 'mailing'
  if person.addresses.present?
    if person.addresses.select{|address| address.kind == address_to_use && address.state == 'DC'}.present?
      return true
    else
      return false
    end
  else
    return ""
  end
end

def enrollments_for_family(family)
  HbxEnrollment.where(family_id: family.id)
end

def document_due_date(family)
  enrolled_contingent_enrollment = enrollments_for_family(family).outstanding_enrollments.first
  if enrolled_contingent_enrollment.present?
    if enrolled_contingent_enrollment.special_verification_period.present?
      enrolled_contingent_enrollment.special_verification_period.strftime("%m/%d/%Y")
    else
      (TimeKeeper.date_of_record+95.days).strftime("%m/%d/%Y")
    end
  else
    nil
  end
end

def is_family_renewing(family, current_year)
  enrollments_for_family(family).where(
    :aasm_state.in => ["coverage_selected", "unverified", "coverage_terminated"],
    kind: "individual",
    :effective_on => {:"$gte" => Date.new(current_year,1,1), :"$lte" => Date.new(current_year,12,31)}
  ).present?
end

def check_for_outstanding_verification_types(person)
  outstanding_verification_types = []

  if person.consumer_role.outstanding_verification_types.present?
    outstanding_verification_types << person.consumer_role.outstanding_verification_types.map(&:type_name)
  else
    return nil
  end

  outstanding_verification_types
end

def has_current_aptc_hbx_enrollment(family)
  enrollments = enrollments_for_family(family) rescue []
  enrollments.any? {|enrollment| (enrollment.effective_on.year == TimeKeeper.date_of_record.next_year.year) && enrollment.applied_aptc_amount > 0}
end

while offset <= enrollment_count
  HbxEnrollment.by_year(current_year + 1).individual_market.offset(offset).limit(batch_size).each do |policy|
    begin
      next unless is_family_renewing(policy.family, current_year)
      next if policy.product.nil?
      next unless product_ids.include?(policy.product_id)
      next if policy.effective_on < Date.new(current_year + 1, 01, 01)
      next unless ["auto_renewing", "coverage_selected", "unverified", "renewing_coverage_selected"].include?(policy.aasm_state)
      next unless ['01', '03', ''].include?(policy.product.csr_variant_id) #includes dental plans - csr_variant_id - ''
      next if policy.product.benefit_market_kind != :aca_individual
      next if (!(['unassisted_qhp', 'individual'].include? policy.kind)) || has_current_aptc_hbx_enrollment(policy.family)

      person = policy.subscriber.person

      add_to_csv(csv, policy, person, "No", check_for_outstanding_verification_types(person), document_due_date(policy.family))

      policy.hbx_enrollment_members.each do |hbx_enrollment_member|
        add_to_csv(csv, policy, hbx_enrollment_member.person, "Yes", check_for_outstanding_verification_types(hbx_enrollment_member.person), document_due_date(policy.family)) if hbx_enrollment_member.person != person
      end
      puts "************** Inserting into CSV #{person.hbx_id} ***************" 
    rescue => e
      puts "Error policy id #{policy.id} family id #{policy.family.id}" + e.message + "   " + e.backtrace.first
    end
  end

  offset = offset + batch_size
end
puts "-------------------------------------- End of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
