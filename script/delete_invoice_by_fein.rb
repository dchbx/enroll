#script to delete invoices of initial, conversion and renewing employers
new_employers = Organization.where({
  :'employer_profile.plan_years' => {
    :$elemMatch => {
      :start_on =>  { "$eq" => DateTime.parse("2016-12-01" ) },
      :"aasm_state".in => PlanYear::PUBLISHED
    }}
})

renewing = Organization.where({
  :'employer_profile.profile_source'.ne => 'conversion',
  :'employer_profile.plan_years' => {
    :$elemMatch => {
        :"start_on" => { "$eq" => DateTime.parse("2016-12-01" ) },
        :"aasm_state".in =>  PlanYear::RENEWING_PUBLISHED_STATE
      }
    }
})

conversion_employers = Organization.where({
  :'employer_profile.profile_source' => 'conversion',
  :'employer_profile.plan_years' => {
    :$elemMatch => {
        :"start_on" => { "$eq" => DateTime.parse("2016-12-01" ) },
        :"aasm_state".in =>  PlanYear::RENEWING_PUBLISHED_STATE
      }
    }
})

conversion_employers.each do |organization|
  invoices = organization.invoices.select {|i| i.date == DateTime.parse("2016-11-16") }
  invoices.each do |i|
    puts "destroying invoice #{i.inspect}"
    i.destroy
  end
end
