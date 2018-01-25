
family_count = Family.count

csv = CSV.open("11455_export_ea_multirow_oct_14.csv", "w")
csv << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.subscriber.person.hbx_id
        person.age policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status
        policy.subscriber.person.is_dc_resident? is_dependent)


def add_to_csv(csv, policy, person, is_dependent)
  csv << [policy.family.id, policy.hbx_id, policy.effective_on, policy.aasm_state, policy.plan.coverage_kind, policy.plan.metal_level, person.hbx_id,
          person.age_on(DateTime.new(2017,1,1)), person.is_incarcerated, person.citizen_status,
          person.is_dc_resident?] + [is_dependent]
end

  Family.batch_size(1000).no_timeout.all.each do |f|
    f.households.each do |hh|
      hh.hbx_enrollments.each do |policy|
        begin
          next if policy.plan.nil?
          next if policy.effective_on < Date.new(2016, 01, 01)
          next if !policy.is_active?
          next if (!(['unassisted_qhp', 'individual'].include? policy.kind)) || policy.family.has_aptc_hbx_enrollment?

          person = policy.subscriber.person
          add_to_csv(csv, policy, person, false)

          policy.hbx_enrollment_members.each do |hbx_enrollment_member|
            add_to_csv(csv, policy, hbx_enrollment_member.person, true) if hbx_enrollment_member.person != person
          end

        rescue => e
          puts "Error policy id #{policy.id} family id #{policy.family.id}" + e.message + "   " + e.backtrace.first
        end
      end
    end
  end

