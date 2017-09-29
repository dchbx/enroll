batch_size = 500
offset = 0
family_count = Family.count

@data_hash = {}
CSV.foreach('uqhp_projected_eligibility_notice_report_final.csv',:headers =>true).each do |d|
  if @data_hash[d["family.id"]].present?
    hbx_ids = @data_hash[d["family.id"]].collect{|r| r['policy.subscriber.person.hbx_id']}
    next if hbx_ids.include?(d["policy.subscriber.person.hbx_id"])
    @data_hash[d["family.id"]] << d
  else
    @data_hash[d["family.id"]] = [d]
  end
end

plan_ids = Plan.where(:active_year => 2017, :market => "individual").map(&:_id)

csv = CSV.open("uqhp_remaingin_export_ea_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.plan.plan_name policy.subscriber.person.hbx_id
        policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status
        policy.subscriber.person.is_dc_resident? is_dependent)


def add_to_csv(csv, policy, person, is_dependent)
  csv << [policy.family.id, policy.hbx_id, policy.effective_on, policy.aasm_state, policy.plan.coverage_kind, policy.plan.metal_level, policy.plan.name, person.hbx_id,
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

def has_current_aptc_hbx_enrollment(family)
  enrollments = family.latest_household.hbx_enrollments rescue []
  enrollments.any? {|enrollment| (enrollment.effective_on.year == TimeKeeper.date_of_record.year) && enrollment.applied_aptc_amount > 0}
end

while offset < family_count
  Family.offset(offset).limit(batch_size).flat_map(&:households).flat_map(&:hbx_enrollments).each do |policy|
    begin
      next if @data_hash.key?(policy.family.id.to_s)
      next if policy.plan.nil?
      next if !plan_ids.include?(policy.plan_id)
      next if policy.effective_on < Date.new(2017, 01, 01)
      next if !policy.is_active?
      next if !(['01', '03', ''].include?(policy.plan.csr_variant_id))#includes dental plans - csr_variant_id - ''
      next if policy.plan.market != 'individual'
      next if (!(['unassisted_qhp', 'individual'].include? policy.kind)) || has_current_aptc_hbx_enrollment(policy.family)

      person = policy.subscriber.person

      add_to_csv(csv, policy, person, false)

      policy.hbx_enrollment_members.each do |hbx_enrollment_member|
        add_to_csv(csv, policy, hbx_enrollment_member.person, true) if hbx_enrollment_member.person != person
      end

    rescue => e
      puts "Error policy id #{policy.id} family id #{policy.family.id}" + e.message + "   " + e.backtrace.first
    end
  end

  offset = offset + batch_size
end