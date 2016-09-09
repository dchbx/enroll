batch_size = 500
offset = 0
family_count = Family.count

csv = CSV.open("10655_export_ea.csv", "w")
csv << %w(policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.subscriber.person.hbx_id
        policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status
        policy.subscriber.person.is_dc_resident? is_dependent)


def add_to_csv(csv, policy, person, is_dependent)
  csv << [policy.hbx_id, policy.effective_on, policy.aasm_state, policy.plan.coverage_kind, policy.plan.metal_level, person.hbx_id,
          person.is_incarcerated, person.citizen_status,
          person.is_dc_resident?] + [is_dependent]
end

while offset < family_count
  Family.offset(offset).limit(batch_size).flat_map(&:households).flat_map(&:hbx_enrollments).each do |policy|
    begin
      next if policy.plan.nil?
      next if policy.effective_on < Date.new(2016, 01, 01)
      next if !policy.is_active?
      next if policy.plan.csr_variant_id != '01'
      next if (policy.plan.coverage_kind != 'health') || (policy.plan.metal_level == "catastrophic") ||
          (!(['unassisted_qhp', 'individual'].include? policy.kind)) || policy.family.has_aptc_hbx_enrollment?

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