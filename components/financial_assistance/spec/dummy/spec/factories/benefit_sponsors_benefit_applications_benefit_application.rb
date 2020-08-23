# frozen_string_literal: true

FactoryBot.define do

  sequence(:random_count) do |_n|
    @random ||= Random.new
    @random_counts ||= (1..25).to_a.shuffle
    @random_counts[@random.rand(25)]
  end

  factory :benefit_sponsors_benefit_application, class: 'BenefitSponsors::BenefitApplications::BenefitApplication' do

    fte_count   { FactoryBot.generate(:random_count) }
    pte_count   { FactoryBot.generate(:random_count) }
    msp_count   { FactoryBot.generate(:random_count) }

    # design using defining module spec helpers
    effective_period do
      if default_effective_period.present?
        default_effective_period
      else
        start_on  = TimeKeeper.date_of_record.beginning_of_month
        end_on    = start_on + 1.year - 1.day
        start_on..end_on
      end
    end

    open_enrollment_period do
      if default_open_enrollment_period.present?
        default_open_enrollment_period
      else
        start_on = effective_period.min.prev_month
        end_on   = start_on + 9.days
        start_on..end_on
      end
    end

    recorded_service_areas   { [create(:benefit_markets_locations_service_area)] }
    recorded_rating_area     { create(:benefit_markets_locations_rating_area) }
    recorded_sic_code        { "021" }

    transient do
      predecessor_application_state { :active }
      imported_application_state { :imported }
      default_effective_period { nil }
      default_open_enrollment_period { nil }
      package_kind { :single_issuer }
      dental_package_kind { :single_product }
      dental_sponsored_benefit { false }
      predecessor_application_catalog { false }
      passed_benefit_sponsor_catalog { nil }
    end

    trait :without_benefit_sponsor_catalog

    trait :with_benefit_sponsor_catalog do
      after(:build) do |benefit_application, evaluator|
        benefit_sponsorship ||= benefit_application.benefit_sponsorship
        benefit_sponsor_catalog = evaluator.passed_benefit_sponsor_catalog || benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.effective_period.min)
        benefit_sponsor_catalog.save
        benefit_application.benefit_sponsor_catalog = (benefit_sponsor_catalog || ::BenefitMarkets::BenefitSponsorCatalog.new)
        benefit_application.benefit_sponsor_catalog.service_areas = benefit_application.recorded_service_areas
      end
    end

    trait :with_benefit_sponsorship do
      after(:build) do |benefit_application, _evaluator|
        benefit_sponsorship ||= benefit_application.benefit_sponsorship
        benefit_sponsorship { create(:benefit_sponsors_benefit_sponsorship, :with_full_package)} unless benefit_sponsorship.present?
      end
    end

    trait :with_benefit_package do
      association :benefit_sponsor_catalog, factory: :benefit_markets_benefit_sponsor_catalog
      after(:build) do |benefit_application, evaluator|
        product_package = benefit_application.benefit_sponsor_catalog.product_packages.by_package_kind(evaluator.package_kind).by_product_kind(:health).first
        if evaluator.dental_sponsored_benefit
          dental_product_package = benefit_application.benefit_sponsor_catalog.product_packages.by_package_kind(evaluator.dental_package_kind).by_product_kind(:dental).first
          benefit_application.benefit_packages = [create(:benefit_sponsors_benefit_packages_benefit_package,
                                                         benefit_application: benefit_application,
                                                         product_package: product_package,
                                                         dental_product_package: dental_product_package,
                                                         dental_sponsored_benefit: true)]
        else
          benefit_application.benefit_packages = [create(:benefit_sponsors_benefit_packages_benefit_package,
                                                         product_package: product_package,
                                                         benefit_application: benefit_application)]
        end
      end
    end

    trait :with_predecessor_application do
      after(:build) do |benefit_application, evaluator|

        predecessor_application = FactoryBot.create(:benefit_sponsors_benefit_application,
                                                    (evaluator.predecessor_application_catalog ? :with_benefit_sponsor_catalog : :without_benefit_sponsor_catalog),
                                                    :with_benefit_package,
                                                    benefit_sponsorship: benefit_application.benefit_sponsorship,
                                                    effective_period: (benefit_application.effective_period.begin - 1.year)..((benefit_application.effective_period.end - 1.year).end_of_month),
                                                    open_enrollment_period: (benefit_application.open_enrollment_period.begin - 1.year)..(benefit_application.open_enrollment_period.end - 1.year),
                                                    dental_sponsored_benefit: evaluator.dental_sponsored_benefit,
                                                    aasm_state: evaluator.predecessor_application_state,
                                                    recorded_service_areas: benefit_application.benefit_sponsorship.service_areas_on(benefit_application.effective_period.begin - 1.year))

        benefit_application.predecessor = predecessor_application
        benefit_application.benefit_packages.first.predecessor = predecessor_application.benefit_packages.first
      end
    end

    trait :with_predecessor_expired_application do
      after(:build) do |benefit_application, _evaluator|
        benefit_application.predecessor_application = FactoryBot.create(:benefit_sponsors_benefit_application,
                                                                        :with_benefit_package,
                                                                        :with_benefit_sponsor_catalog,
                                                                        :with_benefit_package,
                                                                        benefit_sponsorship: benefit_application.benefit_sponsorship,
                                                                        effective_period: (benefit_application.effective_period.begin - 1.year)..(benefit_application.effective_period.end - 1.year),
                                                                        open_enrollment_period: (benefit_application.open_enrollment_period.begin - 1.year)..(benefit_application.open_enrollment_period.end - 1.year),
                                                                        recorded_service_areas: benefit_application.benefit_sponsorship.service_areas_on(benefit_application.effective_period.begin - 1.year),
                                                                        aasm_state: :expired)
        benefit_application.predecessor = predecessor_application
        benefit_application.benefit_packages.first.predecessor = predecessor_application.benefit_packages.first
      end
    end

    trait :with_predecessor_imported_application do
      after(:build) do |benefit_application, evaluator|
        predecessor_application = FactoryBot.create(:benefit_sponsors_benefit_application,
                                                    :with_benefit_package,
                                                    benefit_sponsorship: benefit_application.benefit_sponsorship,
                                                    effective_period: (benefit_application.effective_period.begin - 1.year)..(benefit_application.effective_period.end - 1.year),
                                                    open_enrollment_period: (benefit_application.open_enrollment_period.begin - 1.year)..(benefit_application.open_enrollment_period.end - 1.year),
                                                    aasm_state: evaluator.imported_application_state)
        benefit_application.predecessor = predecessor_application
        benefit_application.benefit_packages.first.predecessor = predecessor_application.benefit_packages.first
      end
    end

    trait :with_active do
      after(:build) do |benefit_application, _evaluator|
        start_on  = TimeKeeper.date_of_record.end_of_month + 1.day - 3.months
        end_on    = start_on + 1.year - 1.day
        benefit_application.effective_period = start_on..end_on

        start_on = benefit_application.effective_period.min.prev_month
        end_on   = start_on + 9.days

        benefit_application.open_enrollment_period = start_on..end_on
        benefit_application.aasm_state = :active
      end
    end
  end
end
