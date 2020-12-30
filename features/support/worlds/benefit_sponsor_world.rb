module BenefitSponsorWorld

  def benefit_sponsorship(employer = nil)
    @benefit_sponsorship ||= {}
    return @benefit_sponsorship.values.first if employer.blank?
    @benefit_sponsorship[employer.legal_name] ||= employer.employer_profile.add_benefit_sponsorship.tap do |benefit_sponsorship|
      benefit_sponsorship.save
    end
  end

  def benefit_sponsor_catalog(employer = nil)
    @benefit_sponsor_catalog ||= benefit_sponsorship(employer).benefit_sponsor_catalog_for(effective_period.min).tap(&:save!)
  end

  def issuer_profile
    @issuer_profile ||= FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, assigned_site: site)
  end

end

World(BenefitSponsorWorld)
