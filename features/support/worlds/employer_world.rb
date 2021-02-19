module EmployerWorld
  include ActionView::Helpers::NumberHelper
  # This method is designed to be used in two kinds of scenarios,
  # 1. where there are multiple employers for a scenario and it's called with
  # legal_name to find the right one
  # 2. where there is only one employer for a scenario and no legal_name is needed
  #
  # If no legal_name is specified but an employer has already been created this method
  # defaults to the first employer created
  def employer(legal_name=nil, *traits)
    attributes = traits.extract_options!
    traits.push("with_aca_shop_#{Settings.site.key}_employer_profile".to_sym) unless traits.include? :with_aca_shop_cca_employer_profile_no_attestation
    @organization ||= {}

    # puts "running for legal_name: #{legal_name}"
    # puts "@organization.keys.inspect: #{@organization.keys.inspect}"

    if legal_name.blank?
      if @organization.empty?
        @organization[:default] ||= FactoryBot.create(:benefit_sponsors_organizations_general_organization,
          *traits,
          attributes.merge(site: site)
        )
      else
        @organization.values.first
      end
    else
      @organization[legal_name] ||= FactoryBot.create(
        :benefit_sponsors_organizations_general_organization, *traits,
        attributes.merge(site: site)
      )
    end
  end

  def employer_profile(legal_name = nil)
    employer(legal_name).employer_profile
  end

  def registering_employer
    @registering_organization ||= FactoryBot.build(
      :benefit_sponsors_organizations_general_organization,
      "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym,
      site: site
    )
  end

  def create_employer_staff(staff_name, legal_name, user)
    employer_profile = employer_profile(legal_name)
    person = FactoryBot.create(:person, first_name: staff_name.split(/\s/)[0], last_name: staff_name.split(/\s/)[1], user: user)
    employer_staff_role = create(:employer_staff_role, aasm_state: :active, benefit_sponsor_employer_profile_id: employer_profile.id)
    person.employer_staff_roles << employer_staff_role
    user.roles = ['employer_staff']
    user.update_attributes(last_portal_visited: "/benefit_sponsors/profiles/employers/employer_profiles/#{employer_profile.id}?tab=home")
  end
end

World(EmployerWorld)

And(/^there is an employer (.*?)$/) do |legal_name|
  employer legal_name, legal_name: legal_name, dba: legal_name
  benefit_sponsorship(employer(legal_name))
end

And(/^there is an fehb employer (.*?)$/) do |legal_name|
  employer legal_name, :with_fehb_employer_profile, legal_name: legal_name, dba: legal_name
  benefit_sponsorship(employer(legal_name))
end

And(/^it has an employer (.*?) with no attestation submitted$/) do |legal_name|
  employer legal_name, :with_aca_shop_cca_employer_profile_no_attestation, legal_name: legal_name, dba: legal_name
  benefit_sponsorship(employer(legal_name))
end

Given(/^at least one attestation document status is (.*?)$/) do |status|
  @employer_attestation_status = status
end

And(/^an employer (.*?) exists with statements and premium payments$/) do |legal_name|
  employer legal_name, legal_name: legal_name, dba: legal_name
  benefit_sponsorship = benefit_sponsorship(employer(legal_name))
  @benefit_sponsorship_account = FactoryBot.create(:benefit_sponsors_benefit_sponsorships_benefit_sponsorship_account, :with_financial_transactions, :with_current_statement_activities, benefit_sponsorship: benefit_sponsorship)
end

Given(/^employer (.*?) has hired this broker$/) do |legal_name|
  assign_broker_agency_account
  assign_person_to_broker_agency
  employer_profile(legal_name).hire_broker_agency(broker_agency_profile)
  # Need to fix below later
  employer_profile(legal_name).benefit_sponsorships.first.active_broker_agency_account.update(writing_agent_id: broker.person.broker_role.id)
end

And(/^(.*?) employer has a staff role$/) do |legal_name|
  employer_profile = employer_profile(legal_name)
  employer_staff_role = FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)
  person = FactoryBot.create(:person, employer_staff_roles: [employer_staff_role])
  @staff_role ||= FactoryBot.create(:user, :person => person)
end

And(/^(.*?) employer terminates employees$/) do |legal_name|
  termination_date = TimeKeeper.date_of_record - 1.day
  @census_employees.each do |employee|
    employee.terminate_employment(termination_date)
  end
end

And(/^(.*?) is logged in and on the home page$/) do |legal_name|
  organization = @organization[legal_name]
  employer_profile = organization.employer_profile
  visit benefit_sponsors.profiles_employers_employer_profile_path(employer_profile.id, :tab => 'home')
end

And(/^staff role person logged in$/) do
  login_as @staff_role
end

And /^staff role person clicked on (.*?) tab$/ do |key|
  find(".interaction-click-control-#{key}").click
end

Given(/a consumer role person with family/) do
  person = people['Patrick Doe']
  @person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: 'Employee', last_name: person[:last_name], ssn: person[:ssn], dob: person[:dob])
  FactoryBot.create :family, :with_primary_family_member, person: @person
  FactoryBot.create(:user, person: @person, email: person[:email], password: person[:password], password_confirmation: person[:password])
end

Given(/all products with issuer profile/) do
  @issuer_profile = FactoryBot.create :benefit_sponsors_organizations_issuer_profile
  BenefitMarkets::Products::Product.all.each {|product| product.update_attributes(issuer_profile: @issuer_profile)}
  BenefitMarkets::Products::Product.all.dental_products.each {|dp| dp.update_attributes(dental_level: 'high', dental_plan_kind: 'ppo')}
end

Given(/an employer with initial application/) do
  @sponsorship = employer(nil, :with_aca_shop_dc_employer_profile_initial_application).benefit_sponsorships.first
  @profile = @sponsorship.profile
end

Then(/an application provides health and dental packages/) do
  benefit_application = @sponsorship.benefit_applications.first
  product_package = benefit_application.benefit_sponsor_catalog.product_packages.by_product_kind(:health).first
  dental_product_package = benefit_application.benefit_sponsor_catalog.product_packages.by_product_kind(:dental).first
  benefit_application.benefit_packages = [create(:benefit_sponsors_benefit_packages_benefit_package,
                                                 benefit_application: benefit_application,
                                                 product_package: product_package,
                                                 dental_product_package: dental_product_package,
                                                 dental_sponsored_benefit: true)]
  benefit_application.save!
  product_package.products.each {|product| product.update_attributes(issuer_profile: @issuer_profile)}
end

Then(/there are sponsored benefit offerings for spouse and child/) do
  benefit_application = @sponsorship.benefit_applications.first
  product_package = benefit_application.benefit_sponsor_catalog.product_packages.by_product_kind(:health).first
  benefit_group = @sponsorship.profile.plan_years[0].benefit_groups[0]
  benefit_group.dental_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: 'Spouse').first.update_attributes(is_offered: false)
  benefit_group.dental_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: 'Child Under 26').first.update_attributes(is_offered: true)
  benefit_group.health_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: 'Child Under 26').first.update_attributes(is_offered: true)
  benefit_group.health_sponsored_benefit.update_attributes(product_option_choice: product_package.products.first.issuer_profile.id)
end