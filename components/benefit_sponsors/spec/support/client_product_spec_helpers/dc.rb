require File.join(File.dirname(__FILE__), "..", "benefit_sponsors_pricing_model_spec_helpers")
require File.join(File.dirname(__FILE__), "..", "benefit_sponsors_contribution_model_spec_helpers")

module BenefitSponsors
  module ClientProductSpecHelpers
    module DC
    def dental_shop_product_props_for(
      issuer_profile_id,
      title,
      hios_base,
      effective_period,
      metal_level,
      service_area_id,
      rating_area_id,
      pp_kinds,
      renewal_product_id = nil
    )
      product_id = BSON::ObjectId.new
      product_ptable_id = BSON::ObjectId.new
      product_ptuple_id = BSON::ObjectId.new
      product_props = {
        "_id" => product_id,
        "_type": "BenefitMarkets::Products::DentalProducts::DentalProduct",
        ehb: 0.9942,
        dental_plan_kind: "hmo",
        metal_level_kind: :dental,
        benefit_market_kind: :aca_shop,
        title: title,
        issuer_profile_id: issuer_profile_id,
        hios_id: "#{hios_base}-01",
        dental_level: 'high',
        hios_base_id: hios_base,
        csr_variant_id: "01",
        service_area_id: service_area_id,
        kind: :dental,
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        product_package_kinds: pp_kinds,
        premium_ages: {
          min: 25,
          max: 25
        },
        premium_tables: [
          {
            "_id": product_ptable_id,
            effective_period: {
              min: effective_period.min,
              max: effective_period.max
            },
            rating_area_id: rating_area_id,
            premium_tuples: [{
              "_id": product_ptuple_id,
              age: 25,
              cost: 208.51
            }]
          }
        ],
        is_reference_plan_eligible: true,
        renewal_product_id: renewal_product_id,
        is_standard_plan: true,
        hsa_eligibility: true
      }
    end

    def health_shop_product_props_for(
      issuer_profile_id,
      title,
      hios_base,
      effective_period,
      metal_level,
      service_area_id,
      rating_area_id,
      pp_kinds,
      renewal_product_id = nil
    )
      product_id = BSON::ObjectId.new
      product_ptable_id = BSON::ObjectId.new
      product_ptuple_id = BSON::ObjectId.new
      product_props = {
        "_id" => product_id,
        "_type": "BenefitMarkets::Products::HealthProducts::HealthProduct",
        ehb: 0.9942,
        health_plan_kind: "hmo",
        metal_level_kind: metal_level.to_sym,
        benefit_market_kind: "aca_shop",
        title: title,
        issuer_profile_id: issuer_profile_id,
        hios_id: "#{hios_base}-01",
        hios_base_id: hios_base,
        csr_variant_id: "01",
        service_area_id: service_area_id,
        kind: :health,
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        product_package_kinds: pp_kinds,
        premium_ages: {
          min: 25,
          max: 25
        },
        premium_tables: [
          {
            "_id": product_ptable_id,
            effective_period: {
              min: effective_period.min,
              max: effective_period.max
            },
            rating_area_id: rating_area_id,
            premium_tuples: [{
              "_id": product_ptuple_id,
              age: 25,
              cost: 208.51
            }]
          }
        ],
        is_reference_plan_eligible: true,
        is_standard_plan: true,
        hsa_eligibility: true,
        renewal_product_id: renewal_product_id
      }
    end

    def create_dental_only_carrier_plan_samples(
      issuer_profile_id,
      effective_period,
      rating_area_id,
      renewal_product_props = []
    )

      state_service_area_id = BSON::ObjectId.new

      state_service_area_props = {
        "_id": state_service_area_id,
        active_year: effective_period.min.year,
        issuer_provided_code: "DCS002",
        issuer_provided_title: "Dental Only Issuer State Service Area",
        issuer_profile_id: issuer_profile_id,
        covered_states: [Settings.aca.state_abbreviation]
      }
      BenefitMarkets::Locations::ServiceArea.collection.insert_one(state_service_area_props)
      renewal_id_1 = renewal_product_props.blank? ? nil : renewal_product_props[0]["_id"]
      renewal_id_2 = renewal_product_props.blank? ? nil : renewal_product_props[1]["_id"]
      renewal_id_3 = renewal_product_props.blank? ? nil : renewal_product_props[2]["_id"]
      product_1_props = dental_shop_product_props_for(
        issuer_profile_id,
        "Carrier 3 Dental Only - Dental - State",
        "32345MA0260001",
        effective_period,
        :dental,
        state_service_area_id,
        rating_area_id,
        [:single_product],
        renewal_id_1
      )
      product_2_props = dental_shop_product_props_for(
        issuer_profile_id,
        "Carrier 3 Dental Only - Dental - State",
        "32345MA0260005",
        effective_period,
        :dental,
        state_service_area_id,
        rating_area_id,
        [:single_issuer],
        renewal_id_2
      )
      product_3_props = dental_shop_product_props_for(
        issuer_profile_id,
        "Carrier 3 Dental Only - Dental - State",
        "32345MA0260029",
        effective_period,
        :dental,
        state_service_area_id,
        rating_area_id,
        [:multi_product],
        renewal_id_3
      )
      product_props = [
        product_1_props,
        product_2_props,
        product_3_props
      ]
      #BenefitMarkets::Products::Product.collection.insert_many(product_props)
      product_props
    end

    def create_health_and_dental_carrier_plan_samples(
      issuer_profile_id,
      effective_period,
      rating_area_id,
      renewal_product_props = []
    )
      state_service_area_id = BSON::ObjectId.new

      state_service_area_props = {
        "_id": state_service_area_id,
        active_year: effective_period.min.year,
        issuer_provided_code: "DCS002",
        issuer_provided_title: "Health and Dental Issuer State Service Area",
        issuer_profile_id: issuer_profile_id,
        covered_states: [Settings.aca.state_abbreviation]
      }
      BenefitMarkets::Locations::ServiceArea.collection.insert_one(state_service_area_props)
      renewal_id_1 = renewal_product_props.blank? ? nil : renewal_product_props[0]["_id"]
      renewal_id_3 = renewal_product_props.blank? ? nil : renewal_product_props[1]["_id"]
      renewal_id_4 = renewal_product_props.blank? ? nil : renewal_product_props[2]["_id"]
      renewal_id_5 = renewal_product_props.blank? ? nil : renewal_product_props[3]["_id"]

      product_1_props = health_shop_product_props_for(
        issuer_profile_id,
        "Carrier 2 Health and Dental - Metal and Carrier 1",
        "22345MA0260001",
        effective_period,
        "bronze",
        state_service_area_id,
        rating_area_id,
        [:metal_level,:single_issuer],
        renewal_id_1
      )
      product_3_props = health_shop_product_props_for(
        issuer_profile_id,
        "Carrier 2 Health and Dental - Metal and Composite",
        "22345MA0260003",
        effective_period,
        "silver",
        state_service_area_id,
        rating_area_id,
        [:metal_level,:single_product],
        renewal_id_3
      )
      product_4_props = health_shop_product_props_for(
        issuer_profile_id,
        "Carrier 2 Health and Dental - Composite",
        "22345MA0260004",
        effective_period,
        "bronze",
        state_service_area_id,
        rating_area_id,
        [:single_product],
        renewal_id_4
      )
      product_5_props = dental_shop_product_props_for(
        issuer_profile_id,
        "Carrier 2 Health and Dental - Dental",
        "22345MA0260005",
        effective_period,
        :dental,
        state_service_area_id,
        rating_area_id,
        [:single_product],
        renewal_id_5
      )
      product_props = [
        product_1_props,
        product_3_props,
        product_4_props,
        product_5_props
      ]
      product_props
    end

    def create_health_only_carrier_plan_samples(
      issuer_profile_id,
      effective_period,
      rating_area_id,
      renewal_product_props = []
    )
      state_service_area_id = BSON::ObjectId.new

      state_service_area_props = {
        "_id": state_service_area_id,
        active_year: effective_period.min.year,
        issuer_provided_code: "DCS002",
        issuer_provided_title: "Health Only Issuer State Service Area",
        issuer_profile_id: issuer_profile_id,
        covered_states: [Settings.aca.state_abbreviation]
      }
      BenefitMarkets::Locations::ServiceArea.collection.insert_one(state_service_area_props)
      renewal_id_1 = renewal_product_props.blank? ? nil : renewal_product_props[0]["_id"]
      renewal_id_2 = renewal_product_props.blank? ? nil : renewal_product_props[1]["_id"]
      renewal_id_3 = renewal_product_props.blank? ? nil : renewal_product_props[2]["_id"]
      renewal_id_5 = renewal_product_props.blank? ? nil : renewal_product_props[3]["_id"]

      product_1_props = health_shop_product_props_for(
        issuer_profile_id,
        "Carrier 1 Health - Metal and Carrier",
        "12345MA0260001",
        effective_period,
        "bronze",
        state_service_area_id,
        rating_area_id,
        [:metal_level,:single_issuer],
        renewal_id_1
      )
      product_2_props = health_shop_product_props_for(
        issuer_profile_id,
        "Carrier 1 Health - Metal",
        "12345MA0260002",
        effective_period,
        "gold",
        state_service_area_id,
        rating_area_id,
        [:metal_level],
        renewal_id_2
      )
      product_3_props = health_shop_product_props_for(
        issuer_profile_id,
        "Carrier 1 Health - Carrier 1 - State",
        "12345MA0260003",
        effective_period,
        "silver",
        state_service_area_id,
        rating_area_id,
        [:single_issuer],
        renewal_id_3
      )
      product_5_props = health_shop_product_props_for(
        issuer_profile_id,
        "Carrier 1 Health - Composite 1 - State",
        "12345MA0260005",
        effective_period,
        "gold",
        state_service_area_id,
        rating_area_id,
        [:single_product],
        renewal_id_5
      )
      product_props = [
        product_1_props,
        product_2_props,
        product_3_props,
        product_5_props,
      ]
      product_props
    end

    def create_rating_areas(effective_period)
      rating_area_id = BSON::ObjectId.new
      rating_area_props = {
        "_id": rating_area_id,
        active_year: effective_period.min.year,
        exchange_provided_code: "R-DC001",
        covered_states: [Settings.aca.state_abbreviation]
      }
      BenefitMarkets::Locations::RatingArea.collection.insert_one(rating_area_props)
      rating_area_id
    end

    def create_issuer_profiles(site_id)
      carrier_1_org_id = BSON::ObjectId.from_string('5be1ca559f880b4a3565b0c8')
      carrier_1_issuer_id = BSON::ObjectId.from_string('5be1ca619f880b4a3565b0c9')
      carrier_2_org_id = BSON::ObjectId.from_string('5be1ca6a9f880b4a3565b0ca')
      carrier_2_issuer_id = BSON::ObjectId.from_string('5be1ca729f880b4a3565b0cb')
      carrier_3_org_id = BSON::ObjectId.from_string('5be1ca7a9f880b4a3565b0cc')
      carrier_3_issuer_id = BSON::ObjectId.from_string('5be1ca829f880b4a3565b0cd')
      carrier_1_props = {
        "_id": carrier_1_org_id,
        legal_name: "Carrier 1 Health Only",
        hbx_id: "100199",
        "_type": "BenefitSponsors::Organizations::ExemptOrganization",
        site_id: site_id,
        profiles: [{
          "_id": carrier_1_issuer_id,
          "_type": "BenefitSponsors::Organizations::IssuerProfile",
          issuer_hios_ids: [
            "12345"
          ],
          hbx_carrier_id: "50202",
          issuer_state: Settings.aca.state_abbreviation,
          abbrev: "C1HO",
          offers_sole_source: true,
          shop_dental: false,
          shop_health: true
        }]
      }
      carrier_2_props = {
        "_id": carrier_2_org_id,
        legal_name: "Carrier 2 Health And Dental",
        hbx_id: "110199",
        "_type": "BenefitSponsors::Organizations::ExemptOrganization",
        site_id: site_id,
        profiles: [{
          "_id": carrier_2_issuer_id,
          "_type": "BenefitSponsors::Organizations::IssuerProfile",
          issuer_hios_ids: [
            "22345"
          ],
          hbx_carrier_id: "60202",
          issuer_state: Settings.aca.state_abbreviation,
          abbrev: "C2HD",
          offers_sole_source: true,
          shop_dental: true,
          shop_health: true
        }]
      }
      carrier_3_props = {
        "_id": carrier_3_org_id,
        legal_name: "Carrier 3 Dental Only",
        hbx_id: "120199",
        "_type": "BenefitSponsors::Organizations::ExemptOrganization",
        site_id: site_id,
        profiles: [{
          "_id": carrier_3_issuer_id,
          "_type": "BenefitSponsors::Organizations::IssuerProfile",
          issuer_hios_ids: [
            "32345"
          ],
          hbx_carrier_id: "70202",
          issuer_state: Settings.aca.state_abbreviation,
          abbrev: "C3DO",
          offers_sole_source: true,
          shop_dental: true,
          shop_health: false
        }]
      }
      ::BenefitSponsors::Organizations::Organization.collection.insert_many([
        carrier_1_props,
        carrier_2_props,
        carrier_3_props
      ])
      [carrier_1_issuer_id,carrier_2_issuer_id,carrier_3_issuer_id]
    end

    def build_carriers_and_plans_for_effective_period_at(site, effective_period)
      rating_area_id = BenefitSponsors::ProductSpecHelpers.create_rating_areas(effective_period)
      carrier_id_1, carrier_id_2, carrier_id_3 = BenefitSponsors::ProductSpecHelpers.create_issuer_profiles(site._id)

      carrier_1_product_props = BenefitSponsors::ProductSpecHelpers.create_health_only_carrier_plan_samples(
        carrier_id_1,
        effective_period,
        rating_area_id
      )
      carrier_2_product_props = BenefitSponsors::ProductSpecHelpers.create_health_and_dental_carrier_plan_samples(
        carrier_id_2,
        effective_period,
        rating_area_id
      )
      carrier_3_product_props = BenefitSponsors::ProductSpecHelpers.create_dental_only_carrier_plan_samples(
        carrier_id_3,
        effective_period,
        rating_area_id
      )
      carrier_1_product_props + carrier_2_product_props + carrier_3_product_props
    end

    def sole_source_health_product_package_from_product_props(product_props_list, effective_period)
      selected_products = product_props_list.select do |p_props|
        p_props[:product_package_kinds].include?(:single_product) && (p_props[:kind] == :health)
      end
      product_package_id = BSON::ObjectId.new
      {
        "_id": product_package_id,
        title: "Single Product",
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        benefit_kind: :aca_shop,
        product_kind: :health,
        package_kind: :single_product,
        products: selected_products,
        pricing_model: ::BenefitSponsors::PricingModelSpecHelpers.list_bill_pricing_model,
        contribution_model: ::BenefitSponsors::ContributionModelSpecHelpers.list_bill_contribution_model,
        contribution_models: ::BenefitSponsors::ContributionModelSpecHelpers.contribution_models
      }
    end

    def metal_level_health_product_package_from_product_props(product_props_list, effective_period)
      selected_products = product_props_list.select do |p_props|
        p_props[:product_package_kinds].include?(:metal_level) && (p_props[:kind] == :health)
      end
      product_package_id = BSON::ObjectId.new
      {
        "_id": product_package_id,
        title: "Metal Level",
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        benefit_kind: :aca_shop,
        product_kind: :health,
        package_kind: :metal_level,
        products: selected_products,
        pricing_model: ::BenefitSponsors::PricingModelSpecHelpers.list_bill_pricing_model,
        contribution_model: ::BenefitSponsors::ContributionModelSpecHelpers.list_bill_contribution_model,
        contribution_models: ::BenefitSponsors::ContributionModelSpecHelpers.contribution_models
      }
    end

    def single_issuer_health_product_package_from_product_props(product_props_list, effective_period)
      selected_products = product_props_list.select do |p_props|
        p_props[:product_package_kinds].include?(:single_issuer) && (p_props[:kind] == :health)
      end
      product_package_id = BSON::ObjectId.new
      {
        "_id": product_package_id,
        title: "Single Issuer",
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        benefit_kind: :aca_shop,
        product_kind: :health,
        package_kind: :single_issuer,
        products: selected_products,
        pricing_model: ::BenefitSponsors::PricingModelSpecHelpers.list_bill_pricing_model,
        contribution_model: ::BenefitSponsors::ContributionModelSpecHelpers.list_bill_contribution_model,
        contribution_models: ::BenefitSponsors::ContributionModelSpecHelpers.contribution_models
      }
    end
    
    def metal_level_health_product_package_from_product_props(product_props_list, effective_period)
      selected_products = product_props_list.select do |p_props|
        p_props[:product_package_kinds].include?(:metal_level) && (p_props[:kind] == :health)
      end
      product_package_id = BSON::ObjectId.new
      {
        "_id": product_package_id,
        title: "Metal Level",
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        benefit_kind: :aca_shop,
        product_kind: :health,
        package_kind: :metal_level,
        products: selected_products,
        pricing_model: ::BenefitSponsors::PricingModelSpecHelpers.list_bill_pricing_model,
        contribution_model: ::BenefitSponsors::ContributionModelSpecHelpers.list_bill_contribution_model,
        contribution_models: ::BenefitSponsors::ContributionModelSpecHelpers.contribution_models
      }
    end

    def dental_multi_product_package_from_product_props(product_props_list, effective_period)
      selected_products = product_props_list.select do |p_props|
        p_props[:product_package_kinds].include?(:multi_product) && (p_props[:kind] == :dental)
      end
      product_package_id = BSON::ObjectId.new
      {
        "_id": product_package_id,
        title: "Dental - Multi-Product",
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        benefit_kind: :aca_shop,
        product_kind: :dental,
        package_kind: :multi_product,
        products: selected_products,
        pricing_model: ::BenefitSponsors::PricingModelSpecHelpers.list_bill_pricing_model,
        contribution_model: ::BenefitSponsors::ContributionModelSpecHelpers.list_bill_contribution_model,
        contribution_models: ::BenefitSponsors::ContributionModelSpecHelpers.contribution_models
      }
    end

    def dental_single_issuer_product_package_from_product_props(product_props_list, effective_period)
      selected_products = product_props_list.select do |p_props|
        p_props[:product_package_kinds].include?(:single_issuer) && (p_props[:kind] == :dental)
      end
      product_package_id = BSON::ObjectId.new
      {
        "_id": product_package_id,
        title: "Dental - Single Issuer",
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        benefit_kind: :aca_shop,
        product_kind: :dental,
        package_kind: :single_issuer,
        products: selected_products,
        pricing_model: ::BenefitSponsors::PricingModelSpecHelpers.list_bill_pricing_model,
        contribution_model: ::BenefitSponsors::ContributionModelSpecHelpers.list_bill_contribution_model,
        contribution_models: ::BenefitSponsors::ContributionModelSpecHelpers.contribution_models
      }
    end

    def dental_single_product_product_package_from_product_props(product_props_list, effective_period)
      selected_products = product_props_list.select do |p_props|
        p_props[:product_package_kinds].include?(:single_product) && (p_props[:kind] == :dental)
      end
      product_package_id = BSON::ObjectId.new
      {
        "_id": product_package_id,
        title: "Dental - Single Product",
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        benefit_kind: :aca_shop,
        product_kind: :dental,
        package_kind: :single_product,
        products: selected_products,
        pricing_model: ::BenefitSponsors::PricingModelSpecHelpers.list_bill_pricing_model,
        contribution_model: ::BenefitSponsors::ContributionModelSpecHelpers.list_bill_contribution_model,
        contribution_models: ::BenefitSponsors::ContributionModelSpecHelpers.contribution_models
      }
    end

    def shared_benefit_market_catalog_properties
=begin
      {
        sponsor_market_policy: {
          _type: "BenefitMarkets::MarketPolicies::SponsorMarketPolicy",
          _id: BSON::ObjectId.new,
          roster_size_rule: {
            min: 0,
            max: 0
          },
          full_time_employee_size_rule: {
            min: 0,
            max: 0
          },
          part_time_employee_size_rule: {
            min: 0,
            max: 0
          },
          rostered_non_owner_size_rule: 0,
          benefit_categories: [ :any ]
        },
        member_market_policy: {
          _type: "BenefitMarkets::MarketPolicies::MemberMarketPolicy",
          _id: BSON::ObjectId.new,
          age_range_policy: {
            min: 0,
            max: 0
          },
          child_age_off_policy: 26,
          incarceration_status_policy: [:any],
          citizenship_status_policy: [:any],
          residency_status_policy: [:any],
          ethnicity_policy: [:any],
          product_dependencies_policy: [:any],
          cost_sharing_policy: "",
          lawful_presence_status_policy: ""
        }
      }
=end
      {}
    end

    def construct_simple_benefit_market_catalog(site, benefit_market, effective_period)
      product_list = build_carriers_and_plans_for_effective_period_at(site, effective_period)
      benefit_market_catalog_id = BSON::ObjectId.new
      benefit_market_catalog_props = {
        "_id": benefit_market_catalog_id,
        application_interval_kind: :monthly,
        probation_period_kinds: [ 
          :first_of_month_before_15th,
          :date_of_hire,
          :first_of_month,
          :first_of_month_following,
          :first_of_month_after_30_days,
          :first_of_month_after_60_days
        ],
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        title: "MA Health Connector SHOP Benefit Catalog",
        benefit_market_id: benefit_market._id,
        product_packages: [
         metal_level_health_product_package_from_product_props(product_list, effective_period),
         sole_source_health_product_package_from_product_props(product_list, effective_period),
         single_issuer_health_product_package_from_product_props(product_list, effective_period),
         dental_single_product_product_package_from_product_props(product_list, effective_period),
         dental_single_issuer_product_package_from_product_props(product_list, effective_period),
         dental_multi_product_package_from_product_props(product_list, effective_period)
        ]
      }
      BenefitMarkets::BenefitMarketCatalog.collection.insert_one(benefit_market_catalog_props)
      BenefitMarkets::Products::Product.collection.insert_many(product_list)

      benefit_market_catalog_id
    end

    def construct_benefit_market_catalog_with_renewal_catalog(site, benefit_market, effective_period)
      carrier_id_1, carrier_id_2, carrier_id_3 = BenefitSponsors::ProductSpecHelpers.create_issuer_profiles(site._id)

      renewal_ep_min = effective_period.min + 1.year
      renewal_ep_max = effective_period.max + 1.year
      renewal_effective_period = (renewal_ep_min..renewal_ep_max)

      renewal_rating_area_id = BenefitSponsors::ProductSpecHelpers.create_rating_areas(renewal_effective_period)

      carrier_1_renewal_product_props = BenefitSponsors::ProductSpecHelpers.create_health_only_carrier_plan_samples(
        carrier_id_1,
        renewal_effective_period,
        renewal_rating_area_id
      )
      carrier_2_renewal_product_props = BenefitSponsors::ProductSpecHelpers.create_health_and_dental_carrier_plan_samples(
        carrier_id_2,
        renewal_effective_period,
        renewal_rating_area_id
      )
      carrier_3_renewal_product_props = BenefitSponsors::ProductSpecHelpers.create_dental_only_carrier_plan_samples(
        carrier_id_3,
        renewal_effective_period,
        renewal_rating_area_id
      )
      renewal_product_list = carrier_1_renewal_product_props + carrier_2_renewal_product_props + carrier_3_renewal_product_props

      renewal_benefit_market_catalog_id = BSON::ObjectId.new
      renewal_benefit_market_catalog_props = {
        "_id": renewal_benefit_market_catalog_id,
        application_interval_kind: :monthly,
        probation_period_kinds: [ 
          :first_of_month_before_15th,
          :date_of_hire,
          :first_of_month,
          :first_of_month_following,
          :first_of_month_after_30_days,
          :first_of_month_after_60_days
        ],
        application_period: {
          min: renewal_effective_period.min,
          max: renewal_effective_period.max
        },
        title: "MA Health Connector SHOP Benefit Catalog",
        benefit_market_id: benefit_market._id,
        product_packages: [
         metal_level_health_product_package_from_product_props(renewal_product_list, renewal_effective_period),
         sole_source_health_product_package_from_product_props(renewal_product_list, renewal_effective_period),
         single_issuer_health_product_package_from_product_props(renewal_product_list, renewal_effective_period),
         dental_single_product_product_package_from_product_props(renewal_product_list, renewal_effective_period),
         dental_single_issuer_product_package_from_product_props(renewal_product_list, renewal_effective_period),
         dental_multi_product_package_from_product_props(renewal_product_list, renewal_effective_period)
        ]
      }

      rating_area_id = BenefitSponsors::ProductSpecHelpers.create_rating_areas(effective_period)

      carrier_1_product_props = BenefitSponsors::ProductSpecHelpers.create_health_only_carrier_plan_samples(
        carrier_id_1,
        effective_period,
        rating_area_id,
        carrier_1_renewal_product_props
      )
      carrier_2_product_props = BenefitSponsors::ProductSpecHelpers.create_health_and_dental_carrier_plan_samples(
        carrier_id_2,
        effective_period,
        rating_area_id,
        carrier_2_renewal_product_props
      )
      carrier_3_product_props = BenefitSponsors::ProductSpecHelpers.create_dental_only_carrier_plan_samples(
        carrier_id_3,
        effective_period,
        rating_area_id,
        carrier_3_renewal_product_props
      )
      product_list = carrier_1_product_props + carrier_2_product_props + carrier_3_product_props

      benefit_market_catalog_id = BSON::ObjectId.new
      benefit_market_catalog_props = {
        "_id": benefit_market_catalog_id,
        application_interval_kind: :monthly,
        probation_period_kinds: [ 
          :first_of_month_before_15th,
          :date_of_hire,
          :first_of_month,
          :first_of_month_following,
          :first_of_month_after_30_days,
          :first_of_month_after_60_days
        ],
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        title: "MA Health Connector SHOP Benefit Catalog",
        benefit_market_id: benefit_market._id,
        product_packages: [
         metal_level_health_product_package_from_product_props(product_list, effective_period),
         sole_source_health_product_package_from_product_props(product_list, effective_period),
         single_issuer_health_product_package_from_product_props(product_list, effective_period),
         dental_single_product_product_package_from_product_props(product_list, effective_period),
         dental_single_issuer_product_package_from_product_props(product_list, effective_period),
         dental_multi_product_package_from_product_props(product_list, effective_period)
        ]
      }
      #BenefitMarkets::BenefitMarketCatalog.collection.insert_one(benefit_market_catalog_props)
      BenefitMarkets::BenefitMarketCatalog.collection.insert_many([renewal_benefit_market_catalog_props, benefit_market_catalog_props])

      BenefitMarkets::Products::Product.collection.insert_many(renewal_product_list + product_list)
    end

    def construct_benefit_market_catalog_with_renewal_and_previous_catalog(site, benefit_market, effective_period)
      carrier_id_1, carrier_id_2, carrier_id_3 = BenefitSponsors::ProductSpecHelpers.create_issuer_profiles(site._id)

      renewal_ep_min = effective_period.min + 1.year
      renewal_ep_max = effective_period.max + 1.year
      renewal_effective_period = (renewal_ep_min..renewal_ep_max)

      renewal_rating_area_id = BenefitSponsors::ProductSpecHelpers.create_rating_areas(renewal_effective_period)

      carrier_1_renewal_product_props = BenefitSponsors::ProductSpecHelpers.create_health_only_carrier_plan_samples(
        carrier_id_1,
        renewal_effective_period,
        renewal_rating_area_id
      )
      carrier_2_renewal_product_props = BenefitSponsors::ProductSpecHelpers.create_health_and_dental_carrier_plan_samples(
        carrier_id_2,
        renewal_effective_period,
        renewal_rating_area_id
      )
      carrier_3_renewal_product_props = BenefitSponsors::ProductSpecHelpers.create_dental_only_carrier_plan_samples(
        carrier_id_3,
        renewal_effective_period,
        renewal_rating_area_id
      )
      renewal_product_list = carrier_1_renewal_product_props + carrier_2_renewal_product_props + carrier_3_renewal_product_props

      renewal_benefit_market_catalog_id = BSON::ObjectId.new
      renewal_benefit_market_catalog_props = {
        "_id": renewal_benefit_market_catalog_id,
        application_interval_kind: :monthly,
        probation_period_kinds: [ 
          :first_of_month_before_15th,
          :date_of_hire,
          :first_of_month,
          :first_of_month_following,
          :first_of_month_after_30_days,
          :first_of_month_after_60_days
        ],
        application_period: {
          min: renewal_effective_period.min,
          max: renewal_effective_period.max
        },
        title: "MA Health Connector SHOP Benefit Catalog",
        benefit_market_id: benefit_market._id,
        product_packages: [
          metal_level_health_product_package_from_product_props(renewal_product_list, renewal_effective_period),
          sole_source_health_product_package_from_product_props(renewal_product_list, renewal_effective_period),
          single_issuer_health_product_package_from_product_props(renewal_product_list, renewal_effective_period),
          dental_single_product_product_package_from_product_props(renewal_product_list, renewal_effective_period),
          dental_single_issuer_product_package_from_product_props(renewal_product_list, renewal_effective_period),
          dental_multi_product_package_from_product_props(renewal_product_list, renewal_effective_period)
        ]
      }.merge(shared_benefit_market_catalog_properties)
      #BenefitMarkets::BenefitMarketCatalog.collection.insert_one(renewal_benefit_market_catalog_props)

      rating_area_id = BenefitSponsors::ProductSpecHelpers.create_rating_areas(effective_period)

      carrier_1_product_props = BenefitSponsors::ProductSpecHelpers.create_health_only_carrier_plan_samples(
        carrier_id_1,
        effective_period,
        rating_area_id,
        carrier_1_renewal_product_props
      )
      carrier_2_product_props = BenefitSponsors::ProductSpecHelpers.create_health_and_dental_carrier_plan_samples(
        carrier_id_2,
        effective_period,
        rating_area_id,
        carrier_2_renewal_product_props
      )
      carrier_3_product_props = BenefitSponsors::ProductSpecHelpers.create_dental_only_carrier_plan_samples(
        carrier_id_3,
        effective_period,
        rating_area_id,
        carrier_3_renewal_product_props
      )
      product_list = carrier_1_product_props + carrier_2_product_props + carrier_3_product_props

      benefit_market_catalog_id = BSON::ObjectId.new
      benefit_market_catalog_props = {
        "_id": benefit_market_catalog_id,
        application_interval_kind: :monthly,
        probation_period_kinds: [ 
          :first_of_month_before_15th,
          :date_of_hire,
          :first_of_month,
          :first_of_month_following,
          :first_of_month_after_30_days,
          :first_of_month_after_60_days
        ],
        application_period: {
          min: effective_period.min,
          max: effective_period.max
        },
        title: "MA Health Connector SHOP Benefit Catalog",
        benefit_market_id: benefit_market._id,
        product_packages: [
         metal_level_health_product_package_from_product_props(product_list, effective_period),
         sole_source_health_product_package_from_product_props(product_list, effective_period),
         single_issuer_health_product_package_from_product_props(product_list, effective_period),
         dental_single_product_product_package_from_product_props(product_list, effective_period),
         dental_single_issuer_product_package_from_product_props(product_list, effective_period),
         dental_multi_product_package_from_product_props(product_list, effective_period)
        ],
        created_at: Time.now,
        updated_at: Time.now
      }.merge(shared_benefit_market_catalog_properties)
      #BenefitMarkets::BenefitMarketCatalog.collection.insert_one(benefit_market_catalog_props)

      previous_ep_min = effective_period.min - 1.year
      previous_ep_max = effective_period.max - 1.year
      previous_effective_period = (previous_ep_min..previous_ep_max)

      previous_rating_area_id = BenefitSponsors::ProductSpecHelpers.create_rating_areas(previous_effective_period)

      previous_carrier_1_product_props = BenefitSponsors::ProductSpecHelpers.create_health_only_carrier_plan_samples(
        carrier_id_1,
        previous_effective_period,
        previous_rating_area_id,
        carrier_1_product_props
      )
      previous_carrier_2_product_props = BenefitSponsors::ProductSpecHelpers.create_health_and_dental_carrier_plan_samples(
        carrier_id_2,
        previous_effective_period,
        previous_rating_area_id,
        carrier_2_product_props
      )
      previous_carrier_3_product_props = BenefitSponsors::ProductSpecHelpers.create_dental_only_carrier_plan_samples(
        carrier_id_3,
        previous_effective_period,
        previous_rating_area_id,
        carrier_3_product_props
      )
      previous_product_list = previous_carrier_1_product_props + previous_carrier_2_product_props + previous_carrier_3_product_props

      previous_benefit_market_catalog_id = BSON::ObjectId.new
      previous_benefit_market_catalog_props = {
        "_id": previous_benefit_market_catalog_id,
        application_interval_kind: :monthly,
        probation_period_kinds: [ 
          :first_of_month_before_15th,
          :date_of_hire,
          :first_of_month,
          :first_of_month_following,
          :first_of_month_after_30_days,
          :first_of_month_after_60_days
        ],
        application_period: {
          min: previous_effective_period.min,
          max: previous_effective_period.max
        },
        title: "MA Health Connector SHOP Benefit Catalog",
        benefit_market_id: benefit_market._id,
        product_packages: [
         metal_level_health_product_package_from_product_props(previous_product_list, previous_effective_period),
         sole_source_health_product_package_from_product_props(previous_product_list, previous_effective_period),
         single_issuer_health_product_package_from_product_props(previous_product_list, previous_effective_period),
         dental_single_product_product_package_from_product_props(previous_product_list, previous_effective_period),
         dental_single_issuer_product_package_from_product_props(previous_product_list, previous_effective_period),
         dental_multi_product_package_from_product_props(previous_product_list, previous_effective_period)
        ]
      }.merge(shared_benefit_market_catalog_properties)
      #BenefitMarkets::BenefitMarketCatalog.collection.insert_one(previous_benefit_market_catalog_props)

      BenefitMarkets::BenefitMarketCatalog.collection.insert_many([renewal_benefit_market_catalog_props, benefit_market_catalog_props, previous_benefit_market_catalog_props])
      BenefitMarkets::Products::Product.collection.insert_many(renewal_product_list + product_list + previous_product_list)
    end
    end
  end
end
