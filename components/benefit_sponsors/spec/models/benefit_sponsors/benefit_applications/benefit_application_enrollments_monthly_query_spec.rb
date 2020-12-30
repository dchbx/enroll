require 'rails_helper'

RSpec.describe BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentsMonthlyQuery, :type => :model, dbclean: :after_each do
  let(:query) { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentsMonthlyQuery.new(benefit_application) }
  let(:benefit_application) do
  	site = FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key)
  	current_effective_date = (TimeKeeper.date_of_record + 2.months).beginning_of_month
  	dates = current_effective_date..(current_effective_date + 20.days)
    application_dates = {
    	effective_period: dates,
    	open_enrollment_period: dates
    }
    organization = FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_no_attestation, site: site)
    employer_profile = organization.employer_profile
    employer_profile.add_benefit_sponsorship.tap do |benefit_sponsorship|
      benefit_sponsorship.save
    end
    benefit_market = site.benefit_markets.first
    issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, assigned_site: site)
    product_kinds = [:health, :dental]
    benefit_market_catalog = FactoryBot.create(:benefit_markets_benefit_market_catalog, :with_product_packages,
        benefit_market: benefit_market,
        product_kinds: product_kinds,
        title: "SHOP Benefits for #{current_effective_date.year}",
        application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
        issuer_profile: issuer_profile
     )
    benefit_sponsorship = employer_profile.active_benefit_sponsorship
    aasm_state = :draft
    package_kind = :single_issuer
    rating_area = FactoryBot.create(:benefit_markets_locations_rating_area, active_year: current_effective_date.year)
    service_area = FactoryBot.create(
      :benefit_markets_locations_rating_area,
      active_year: current_effective_date.year
    )
    benefit_application = FactoryBot.create(
      :benefit_sponsors_benefit_application,
      :with_benefit_sponsor_catalog,
      :with_benefit_package,
      benefit_sponsorship: benefit_sponsorship,
      effective_period: application_dates[:effective_period],
   	  aasm_state: aasm_state,
      open_enrollment_period: application_dates[:open_enrollment_period],
      recorded_rating_area: rating_area,
   	  recorded_service_areas: [],
      package_kind: package_kind,
    )
  end
  let(:person_with_family) { FactoryBot.create(:person, :with_family) }
  let(:person_with_fam_hbx_enrollment) { person_with_family.primary_family.active_household.hbx_enrollments.build }


  describe "#call", dbclean: :after_each do
  	before :each do
  	  person_with_fam_hbx_enrollment.benefit_sponsorship = benefit_application.benefit_sponsorship
      person_with_fam_hbx_enrollment.kind = 'individual'
      person_with_fam_hbx_enrollment.family = person_with_family.primary_family
      person_with_fam_hbx_enrollment.save!
      allow(person_with_fam_hbx_enrollment).to receive(:benefit_group_id).and_return(query.benefit_package_ids.first)
      allow(person_with_fam_hbx_enrollment).to receive(:aasm_state).and_return(:coverage_selected)
  	  allow(Family).to receive(:where).with(
        {
          :"households.hbx_enrollments.benefit_group_id".in => query.benefit_package_ids,
          :"households.hbx_enrollments.aasm_state".in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
        }

  	  ).and_return(Family.all)
  	end
    
    it "should return the expected query" do
      expect(query.call(TimeKeeper.date_of_record)).to eq([])
    end
  end

  describe "#benefit_package_ids" do
  	it "should successfully return benefit package ids" do
      expect(query.benefit_package_ids.length).to be > 0
    end
  end
end
