require File.join(File.dirname(__FILE__), "..", "support/benefit_sponsors_organization_spec_helpers")

RSpec.shared_context "setup initial benefit application", :shared_context => :metadata do
  
  let(:aasm_state)                { :active }
  let(:benefit_sponsorship_state) { :active }
  let(:package_kind)              { :single_issuer }
  let(:dental_package_kind)       { :single_product }
  let(:effective_period)          { current_effective_date..(current_effective_date.next_year.prev_day) }
  let(:open_enrollment_start_on)  { current_effective_date.prev_month }
  let(:open_enrollment_period)    { open_enrollment_start_on..(open_enrollment_start_on+5.days) }
  let!(:abc_organization)         do
    org_id = BenefitSponsors::OrganizationSpecHelpers.with_aca_shop_employer_profile(site)
    BenefitSponsors::Organizations::GeneralOrganization.find(org_id)
  end
  let(:abc_profile)               { abc_organization.employer_profile }
  
  let!(:benefit_sponsorship) { 
    benefit_sponsorship = abc_profile.add_benefit_sponsorship
    benefit_sponsorship.aasm_state = benefit_sponsorship_state
    benefit_sponsorship.save

    benefit_sponsorship
  }
  
  let(:dental_sponsored_benefit) { false }
  #let!(:rating_area)   { create_default(:benefit_markets_locations_rating_area) }
  #let!(:service_areas) { benefit_sponsorship.service_areas_on(effective_period.min) }

  let(:benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(effective_period.min) }

  let!(:initial_application)    { create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog,
                                        :with_benefit_package,
                                        passed_benefit_sponsor_catalog: benefit_sponsor_catalog,
                                        benefit_sponsorship: benefit_sponsorship,
                                        effective_period: effective_period,
                                        aasm_state: aasm_state,
                                        open_enrollment_period: open_enrollment_period,
                                        recorded_rating_area: rating_area,
                                        recorded_service_areas: service_areas,
                                        package_kind: package_kind,
                                        dental_package_kind: dental_package_kind, 
                                        dental_sponsored_benefit: dental_sponsored_benefit,
                                        fte_count: 5,
                                        pte_count: 0,
                                        msp_count: 0
                                )}

  let(:product_package)           { benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
  let(:dental_product_package)    { benefit_sponsor_catalog.product_packages.detect { |package| package.product_kind == :dental && package.package_kind == dental_package_kind } }
  let(:current_benefit_package)   { initial_application.benefit_packages[0] }
end

RSpec.shared_context "setup employees", :shared_context => :metadata do
  let!(:census_employees) { create_list(:census_employee, 5, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }
end

RSpec.shared_context "setup employees with benefits", :shared_context => :metadata do
  # include_context "setup employees"
  let(:roster_size) { 5 }
  let(:enrollment_kinds) { ['health'] }
  let!(:census_employees) { create_list(:census_employee, roster_size, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }

end

RSpec.shared_context "setup renewal application", :shared_context => :metadata do

  let(:predecessor_state)        { :active }
  let(:renewal_state)            { :draft }
  let(:package_kind)             { :single_issuer }
  let(:dental_package_kind)      { :single_product }
  let(:renewal_effective_date)   { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:current_effective_date)   { renewal_effective_date.prev_year }
  let(:effective_period)         { renewal_effective_date..renewal_effective_date.next_year.prev_day }
  let(:open_enrollment_period)   { effective_period.min.prev_month..(effective_period.min - 10.days) }

  #let(:abc_organization)         { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let(:abc_organization)         do
    org_id = BenefitSponsors::OrganizationSpecHelpers.with_aca_shop_employer_profile(site)
    BenefitSponsors::Organizations::GeneralOrganization.find(org_id)
  end
  let(:abc_profile)              { abc_organization.employer_profile }
  let!(:benefit_sponsorship) do
    sponsorship = abc_profile.add_benefit_sponsorship
    sponsorship.save
    sponsorship
  end

  let(:recorded_service_areas)   { 
    current_benefit_market_catalog
    benefit_sponsorship.service_areas_on(effective_period.min)
  }

  let(:dental_sponsored_benefit)           { false }
  let(:current_dental_product_package)     { renewal_benefit_market_catalog.product_packages.detect { |package| package.product_kind == :dental && package.package_kind == dental_package_kind } }
  let(:predeccesor_dental_product_package) { current_benefit_market_catalog.product_packages.detect { |package| package.product_kind == :dental && package.package_kind == dental_package_kind } }
  let(:predecessor_application_catalog)    { false }

  let!(:renewal_application)  { create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog,
                                       :with_benefit_package, :with_predecessor_application,
                                       predecessor_application_state: predecessor_state,
                                       benefit_sponsorship: benefit_sponsorship,
                                       effective_period: effective_period,
                                       aasm_state: renewal_state,
                                       open_enrollment_period: open_enrollment_period,
                                       recorded_rating_area: benefit_sponsorship.rating_area,
                                       recorded_service_areas: recorded_service_areas,
                                       package_kind: package_kind,
                                       dental_package_kind: dental_package_kind,
                                       dental_sponsored_benefit: dental_sponsored_benefit,
                                       predecessor_application_catalog: predecessor_application_catalog)
                              }

  let(:predecessor_application)   { renewal_application.predecessor }
  let(:product_package)           { renewal_application.benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
  let!(:benefit_package) do
    bp = renewal_application.benefit_packages[0]
    bp.title = bp.title + "(#{renewal_application.start_on.year})"
    bp
  end
  let(:current_benefit_package)   { predecessor_application.benefit_packages[0] }
end

RSpec.shared_context "setup expired, and active benefit applications", :shared_context => :metadata do
  include_context 'setup initial benefit application'

  let(:expired_benefit_application) do
    initial_application.update_attributes(aasm_state: :expired)
    initial_application
  end

  let!(:active_benefit_application) do
    application = expired_benefit_application.renew
    application.approve_application!
    application.begin_open_enrollment!
    application.update_attributes(aasm_state: :active)
    application
  end

  let(:expired_benefit_package) { expired_benefit_application.benefit_packages[0] }
  let(:active_benefit_package) { active_benefit_application.benefit_packages[0] }
  let(:expired_sponsored_benefit) { expired_benefit_package.sponsored_benefit_for(coverage_kind) }
  let(:active_sponsored_benefit) { active_benefit_package.sponsored_benefit_for(coverage_kind) }
end

RSpec.shared_context "setup expired, active and renewing benefit applications", :shared_context => :metadata do
  include_context 'setup initial benefit application'

  let(:expired_benefit_application) do
    initial_application.update_attributes(aasm_state: :expired)
    initial_application
  end

  let!(:active_benefit_application) do
    application = expired_benefit_application.renew
    application.approve_application!
    application.begin_open_enrollment!
    application.update_attributes(aasm_state: :active)
    application
  end

  let!(:renewal_benefit_application) do
    application = active_benefit_application.renew
    application.approve_application!
    application.begin_open_enrollment!
    application
  end

  let(:expired_benefit_package) { expired_benefit_application.benefit_packages[0] }
  let(:active_benefit_package) { active_benefit_application.benefit_packages[0] }
  let(:renewal_benefit_package) { renewal_benefit_application.benefit_packages[0] }
  let(:expired_sponsored_benefit) { expired_benefit_package.sponsored_benefit_for(coverage_kind) }
  let(:active_sponsored_benefit) { active_benefit_package.sponsored_benefit_for(coverage_kind) }
  let(:renewal_sponsored_benefit) { renewal_benefit_package.sponsored_benefit_for(coverage_kind) }
end

RSpec.shared_context "setup terminated and active benefit applications", :shared_context => :metadata do
  include_context 'setup initial benefit application'

  let(:benefit_application) do
    initial_application
  end

  let!(:active_benefit_application) do
    application = benefit_application.renew
    application.approve_application!
    application.begin_open_enrollment!
    application.update_attributes(aasm_state: :active)
    application
  end

  let(:terminated_benefit_package) { benefit_application.benefit_packages[0] }
  let(:active_benefit_package) { active_benefit_application.benefit_packages[0] }
  let(:hired_on)        { benefit_application.start_on - 10.days }
  let(:terminated_sponsored_benefit) { terminated_benefit_package.sponsored_benefit_for(coverage_kind) }
  let(:active_sponsored_benefit) { active_benefit_package.sponsored_benefit_for(coverage_kind) }

  let(:terminated_benefit_application) do
    termination_date = benefit_application.start_on + 5.months
    effective_period = benefit_application.start_on..termination_date
    benefit_application.update_attributes(aasm_state: :terminated, terminated_on: termination_date, effective_period: effective_period)
    benefit_application
  end
end

RSpec.shared_context "setup expired and active benefit applications", :shared_context => :metadata do
  include_context 'setup initial benefit application'

  let(:expired_benefit_application) do
    initial_application.update_attributes(aasm_state: :expired)
    initial_application
  end

  let!(:active_benefit_application) do
    application = expired_benefit_application.renew
    application.approve_application!
    application.begin_open_enrollment!
    application.update_attributes(aasm_state: :active)
    application
  end

  let(:expired_benefit_package) { expired_benefit_application.benefit_packages[0] }
  let(:active_benefit_package) { active_benefit_application.benefit_packages[0] }
  let(:expired_sponsored_benefit) { expired_benefit_package.sponsored_benefit_for(coverage_kind) }
  let(:active_sponsored_benefit) { active_benefit_package.sponsored_benefit_for(coverage_kind) }
end
