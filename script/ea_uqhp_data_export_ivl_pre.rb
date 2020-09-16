batch_size = 500
offset = 0
enrollment_count = HbxEnrollment.current_year.count

unless ARGV[0].present?
  puts "Please include the year to pull active enrollments from (e.g. 2020)" unless Rails.env.test?
  exit
end
product_ids = BenefitMarkets::Products::Product.aca_individual_market.by_year(ARGV[0].to_i).pluck(:_id)

csv = CSV.open("ea_uqhp_data_export_ivl_pre_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.plan.plan_name policy.subscriber.person.hbx_id
        policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status
        policy.subscriber.person.is_dc_resident? is_dependent)


def add_to_csv(csv, policy, person, is_dependent)
  csv << [policy.family_id, policy.hbx_id, policy.effective_on, policy.aasm_state, policy.product.kind, policy.product.metal_level_kind, policy.product.title, person.hbx_id,
          person.is_incarcerated, person.citizen_status,
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

while offset < enrollment_count
  HbxEnrollment.current_year.offset(offset).limit(batch_size).each do |policy|
    puts "added to csv #{policy.hbx_id}"
    begin
      next if policy.product.nil?
      next unless product_ids.include?(policy.product_id)
      next unless policy.is_active?
      next unless ['01', '03', ''].include?(policy.product.csr_variant_id) #includes dental plans - csr_variant_id - ''
      next if policy.product.benefit_market_kind != :aca_individual
      next if !(['unassisted_qhp', 'individual'].include? policy.kind) || policy.family.has_aptc_hbx_enrollment?

      person = policy.subscriber.person
      primary_member = policy.family.primary_person

      policy.hbx_enrollment_members.each do |hbx_enrollment_member|
        is_dependent = (primary_member.id != hbx_enrollment_member.person.id)
        add_to_csv(csv, policy, hbx_enrollment_member.person, is_dependent)
      end

    rescue => e
      puts "Error policy id #{policy.id} family id #{policy.family.id}" + e.message + "   " + e.backtrace.first
    end
  end

  offset = offset + batch_size
end
