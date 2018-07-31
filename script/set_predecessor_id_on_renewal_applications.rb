benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
  :"benefit_applications" => { :"$elemMatch" =>
    { 
      :"effective_period.min" => Date.new(2018, 4, 1),
      :"effective_period.max" => Date.new(2018, 7, 31)
    }
  }, :source_kind.in => [:mid_plan_year_conversion]
)

benefit_sponsorships.each do |benefit_sponsorship|
  renewal_application = benefit_sponsorship.benefit_applications.where(
    :"effective_period.min" => Date.new(2018, 8, 1)
  ).first

  myc_application = benefit_sponsorship.benefit_applications.where(
    :"effective_period.min" => Date.new(2018, 4, 1),
    :"effective_period.max" => Date.new(2018, 7, 31)
  ).first

  if renewal_application.update_attributes(:"predecessor_id" => myc_application.id)
    puts "Updated predecessor_id on renewal_application for #{benefit_sponsorship.organization.legal_name}"
  else
    puts "Failure: BenefitApplication update failed. errors: #{renewal_application.errors.full_messages}"
  end

  if (renewal_application.benefit_packages.size != myc_application.benefit_packages.size || renewal_application.benefit_packages.size > 1)
    puts "Failure: BenefitPackage update failed. Benefit Package Size not matched."
    next
  end

  renewal_package = renewal_application.benefit_packages.first
  myc_package = myc_application.benefit_packages.first


  if renewal_package.update_attributes(:"predecessor_id" => myc_package.id)
    puts "Updated predecessor_id on renewal_package for #{benefit_sponsorship.organization.legal_name}"
  else
    puts "Failure: BenefitPackage update failed. errors: #{renewal_package.errors.full_messages}"
  end
end
