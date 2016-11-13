# Run this => RAILS_ENV=production rails r script/trigger_renewal_plan_year.rb
count =0
organizations = Organization.where(:"employer_profile.plan_years" =>
        { :$elemMatch => {
          :"start_on" => (Date.new(2016,2,1)),
          :"aasm_state".in => PlanYear::PUBLISHED
        }
      })
organizations.each do |organization|
  plan_year_renewal_factory = Factories::PlanYearRenewalFactory.new
  plan_year_renewal_factory.employer_profile = organization.employer_profile
  plan_year_renewal_factory.is_congress = false
  plan_year_renewal_factory.renew
  puts "triggered renewal plan year for #{organization.legal_name}"
  count +=1
end

puts "Total effected ER's count is #{count}"