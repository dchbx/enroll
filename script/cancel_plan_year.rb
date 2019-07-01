
def all_enrollments(benefit_groups=[])
  id_lists = benefit_groups.collect(&:_id).uniq
  families = Family.all_enrollments_by_benefit_group_ids(id_lists)
  families.inject([]) do |enrollments, family|
    enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).to_a
  end
end

plan_years = Organization.where(fein: 521623529).first.employer_profile.plan_years

ineligible_py = plan_years.where(aasm_state: "application_ineligible").first
enrollments = all_enrollments(ineligible_py.benefit_groups)
enrollments.each { |enr| enr.cancel_coverage! if enr.may_cancel_coverage? }
puts "canceled enrollments for ineligible plan year" unless Rails.env.test?
ineligible_py.revert_application! if ineligible_py.may_revert_application?
ineligible_py.cancel! if ineligible_py.may_cancel?

puts "canceled ineligible plan year" unless Rails.env.test?

renewing_py = plan_years.where(aasm_state: "renewing_application_ineligible").first
renewing_py.revert_renewal! if renewing_py.may_revert_renewal?
renewing_py.force_publish! if renewing_py.may_force_publish? # triggers notice
renewing_py.advance_date! if renewing_py.may_advance_date?

puts "Moved renewing plan year to renewing enrolling" unless Rails.env.test?

ep = Organization.where(fein: 521623529).first.employer_profile
ep.application_accepted! if ep.may_application_accepted?
