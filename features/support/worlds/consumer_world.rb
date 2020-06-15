module ConsumerWorld
  def active_individual_enrollment(person_record = nil)
    if @active_individual_enrollment
      @active_individual_enrollment
    elsif
      family = person_record.primary_family
      tax_household = FactoryBot.create(:tax_household, effective_ending_on: nil, household: family.households.first)
      eligibility_determination = FactoryBot.create(:eligibility_determination, tax_household: tax_household)
      benefit_package = individual_benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first
      coverage_household = family.active_household.coverage_households.where(:is_immediate_family => true).first
      enrollment = family.active_household.new_hbx_enrollment_from(
        consumer_role: person_record.consumer_role,
        coverage_household: coverage_household,
        benefit_package: benefit_package,
        qle: true
      )
      enrollment.save!
      enrollment.update_attributes!(aasm_state: "coverage_selected")
      @active_individual_enrollment = enrollment
    end
  end

  def ivl_products
    @ivl_products ||= FactoryBot.create(:benefit_package)
  end

  def assign_product_to_active_enrollment(enrollment, product_title)
    if enrollment.is_shop?
      benefit_market_kind = :aca_shop
    else
      benefit_market_kind = :aca_individual
    end
    product = BenefitMarkets::Products::HealthProducts::HealthProduct.where(title: product_title, benefit_market_kind: benefit_market_kind).first
    enrollment.product = product
    enrollment.save!
  end
end

World(ConsumerWorld)

Given(/^individual market benefit products present$/) do
  ivl_products
end

And(/^benefit sponsorship exists for individual market$/) do
  individual_benefit_sponsorship
end

And(/consumer (.*) has active individual enrollment$/) do |named_person|
  person = people[named_person]
  person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first
  active_individual_enrollment(person_rec)
end

And(/only product available is that of active enrollment for (.*)$/) do |named_person|
  person = people[named_person]
  person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first
  enrollment = active_individual_enrollment(person_rec)
  BenefitMarkets::Products::HealthProducts::HealthProduct.all.each do |product|
    unless product.title == enrollment.product.title
      product.destroy
    end
  end
end

And(/^active individual enrollment for (.*) has product with title of (.*)$/) do |named_person, product_title|
  person = people[named_person]
  person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first
  enrollment = active_individual_enrollment(person_rec)
  assign_product_to_active_enrollment(enrollment, product_title)
end

And(/user for consumer (.*) present/) do |named_person|
  person = people[named_person]
  consumer_role(person)
end

And(/user for consumer (.*) is logged in$/) do |named_person|
  person = people[named_person]
  user = User.where(email: person[:email]).first
  login_as(user, :scope => :user)
end

And(/I see (.*) premium for my plan (.*)$/) do |premium_amount, premium_title|
  expect(page).to have_content(premium_amount.to_s)
  expect(page).to have_content(premium_title.to_s)
end

# TODO: Make it easier to select a specific plan by modifying the plan shopping links.
# Currently this only works because of the step
# And only product available is that of active enrollment for Patrick Doe
# So there is one link to select in this text.
When(/(.*) selects the same (.*) plan as the previous year on the plan shopping page$/) do |named_person, coverage_kind|
  person = people[named_person]
  person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first
  family = person_rec.primary_family
  active_enrollment = family.hbx_enrollments.by_coverage_kind(coverage_kind).enrolled.last
  plan = active_enrollment.product
  product_title = plan.title
  sleep 5
  links = page.all('a')
  link = links.detect { |link| link.text == "Select Plan" }
  #link = links.detect { |link| link.text == "Select Plan #{product_title}" }
  link.click
end

And(/(.*) enters their name to sign and clicks the confirmation checkbox$/) do |named_person|
  person = people[named_person]
  fill_in 'first_name_thank_you', with: person[:first_name]
  fill_in 'last_name_thank_you', with: person[:last_name]
  check 'terms_check_thank_you'
end
