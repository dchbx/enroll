#script to delete invoices of initial employers
new_employers = Organization.where({
  :'employer_profile.plan_years' => { 
    :$elemMatch => {
      :start_on =>  { "$eq" => DateTime.parse("2016-12-01" ) },
      :"aasm_state".in => PlanYear::PUBLISHED
    }}
})

new_employers.each do |organization|
  invoices = organization.invoices.select {|i| i.date == DateTime.parse("2016-11-11") } 
  invoices.each do |i| 
    puts "destroying invoice #{i.inspect}"
    i.destroy 
  end
end