# def prepend_zeros(number, n)
#   (n - number.to_s.size).times { number.prepend('0') }
#   number
# end

# CSV.open("#{Rails.root}/CF_ERswithBadHIOS_RESULTS.csv", "w", force_quotes: true) do |csv|
#   CSV.foreach("CF_ERswithBadHIOS.csv", headers: true) do |row|

#    fein = prepend_zeros(row[1].strip, 9)
#    employer_profile = EmployerProfile.find_by_fein(fein)

#    active_plan_year = employer_profile.plan_years.published.first
#    renewing_plan_year = employer_profile.plan_years.renewing_published_state.first

#    csv_row = row.to_a.map{|x| x[1]}

#    if active_plan_year.present?
#     csv_row += [active_plan_year.try(:benefit_groups).first.reference_plan.hios_id, active_plan_year.try(:benefit_groups).first.reference_plan.renewal_plan.hios_id]
#   else
#     csv_row << ['missing', 'missing']
#   end

#    if renewing_plan_year.present?
#     csv_row << renewing_plan_year.try(:benefit_groups).first.reference_plan.hios_id
#   else
#     csv_row << 'missing'
#    end

#    csv << csv_row
#  end
# end


EMPLOYER_HIOS_MAP = {
  "363832940"  => "78079DC0220006-01",
  "522005999"  => "78079DC0230003-01",
  "522013356"  => "78079DC0230003-01",
  "204073133"  => "78079DC0220013-01",
  "454741440"  => "78079DC0220015-01",
  "521505364"  => "86052DC0460007-01",
  "521722025"  => "86052DC0440009-01"
}


def update_reference_plan(plan_year, reference_plan)
  plan_year.benefit_groups.each do |benefit_group|
    benefit_group.reference_plan= reference_plan
    benefit_group.elected_plans= benefit_group.elected_plans_by_option_kind
    benefit_group.save!

    puts "updated #{benefit_group.title} reference_plan with #{reference_plan.hios_id}"
  end
end

EMPLOYER_HIOS_MAP.each do |fein, hios_id|
  employer_profile = EmployerProfile.find_by_fein(fein)
  puts "---processing #{employer_profile.legal_name}"

  plan = Plan.where(:hios_id => hios_id, :active_year => 2015).first
  
  plan_year = employer_profile.plan_years.published.first
  renewing_plan_year = employer_profile.plan_years.renewing.first
  
  if plan_year.benefit_groups[0].reference_plan.hios_id != plan.hios_id
    update_reference_plan(plan_year, plan)
    renewal_plan = plan.renewal_plan
    update_reference_plan(renewing_plan_year, renewal_plan)
  end
end

# count = 0
# Organization.where(:"employer_profile.plan_years" => {
#   :$elemMatch => {
#     :start_on => Date.new(2016, 7, 1),
#     :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE
#   }
# }).each do |organization|

#   active_plan_year = organization.employer_profile.plan_years.published.first

#   reference_plan = active_plan_year.benefit_groups.first.reference_plan

#   renewing_plan_year = organization.employer_profile.plan_years.renewing.first
#   renewing_reference_plan = renewing_plan_year.benefit_groups.first.reference_plan


#   if renewing_reference_plan != reference_plan.renewal_plan
#     count += 1
#     puts organization.legal_name
#   end
# end

# puts count