FactoryGirl.define do
  factory :sponsored_benefits_benefit_catalogs_benefit_catalog, class: 'SponsoredBenefits::BenefitCatalogs::BenefitCatalog' do
    
    title                     "#{Date.today.year} Benefit Catalog"
    application_interval_kind :monthly
    application_period        Date.new(Date.today.year,1,1)..Date.new(Date.today.year,12,31)
    probation_period_kinds    { SponsoredBenefits::PROBATION_PERIOD_KINDS.reduce([]) do |list, kind|
                                list << kind unless [:date_of_hire, :first_of_month_before_15th].include?(kind)
                                list
                              end }

  end
end
