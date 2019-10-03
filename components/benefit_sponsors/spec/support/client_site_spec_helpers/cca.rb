module BenefitSponsors
  module ClientSiteSpecHelpers
    module CCA

    def self.create_site_with_hbx_profile_and_benefit_market(market_kind = :aca_shop)
      site = create_site_with_hbx_profile
      site.benefit_markets << FactoryBot.create(:benefit_markets_benefit_market, kind: market_kind)
      site
    end

    def self.create_site_with_hbx_profile_and_empty_benefit_market(market_kind = :aca_shop)
      site = create_site_with_hbx_profile
      create_shop_benefit_market(site._id)
      site
    end

    def self.create_shop_benefit_market(site_id)
      b_market_id = BSON::ObjectId.from_string('5bd8988aec969cf76b1386da')
      config_id = BSON::ObjectId.from_string('5bd8989cec969cf76b1386db')
      initial_app_config_id = BSON::ObjectId.from_string('5bd898a5ec969cf76b1386dc')
      renewal_app_config_id = BSON::ObjectId.from_string('5bd898b2ec969cf76b1386dd')
      b_market_props = {
        _id: b_market_id,
        title: "ACA SHOP",
        description: "CCA ACA Shop Market",
        kind: :aca_shop,
        site_urn: "cca",
        site_id: site_id,
        configuration: {
          _id: config_id,
          _type: "BenefitMarkets::Configurations::AcaShopConfiguration",
          ee_ct_max: 50,
          ee_ratio_min: 0.666,
          ee_non_owner_ct_min: 1,
          er_contrib_pct_min: 75,
          erlst_e_prior_eod: -30,
          ltst_e_aft_eod: 30,
          ltst_e_aft_ee_roster_cod: 30,
          retroactve_covg_term_max_dys: -60,
          ben_per_min_year: 1,
          ben_per_max_year: 1,
          oe_start_month: 1,
          oe_end_month: 20,
          oe_min_dys: 5,
          oe_grce_min_dys: 5,
          oe_min_adv_dys: 5,
          oe_max_months: 2,
          cobra_epm: 6,
          gf_new_enrollment_trans: 27,
          gf_update_trans_dow: "friday",
          use_simple_er_cal_model: true,
          trans_scheduled_er: true,
          er_transmission_dom: 27,
          enforce_er_attest: true,
          binder_due_dom: 23,
          offerings_constrained_to_service_areas: false,
          trans_er_immed: false,
          stan_indus_class: false,
          carrier_filters_enabled: false,
          initial_application_configuration: {
            _id: initial_app_config_id,
            pub_due_dom: 15,
            erlst_strt_prior_eff_months: -2,
            appeal_per_aft_app_denial_dys: 30,
            quiet_per_end: 28,
            inelig_per_aft_app_denial_dys: 90
          },
          renewal_application_configuration: {
            _id: renewal_app_config_id,
            erlst_strt_prior_eff_months: -2,
            montly_oe_end: 20,
            pub_due_dom: 15,
            force_pub_dom: 16,
            oe_min_dys: 5,
            quiet_per_end: 15
          }
        }
      }
      BenefitMarkets::BenefitMarket.collection.insert_one(b_market_props)
      BenefitMarkets::BenefitMarket.find(b_market_id)
    end

    def self.create_site_with_hbx_profile
      site_id = BSON::ObjectId.from_string('5bd88acbec969cca691386da')
      org_id = BSON::ObjectId.from_string('5bd88af9ec969cca691386db')
      profile_id = BSON::ObjectId.from_string('5bd892efec969ce8e31386da')
      address_id = BSON::ObjectId.from_string('5bd89301ec969ce8e31386db')
      phone_id = BSON::ObjectId.from_string('5bd8930bec969ce8e31386dc')
      inbox_id = BSON::ObjectId.from_string('5bd89315ec969ce8e31386dd')
      office_location_id = BSON::ObjectId.from_string('5bd8931fec969ce8e31386de')
      site_props = {
        _id: site_id,
        site_key: :cca,
        byline: "The Right Place for the Right Plan",
        short_name: "Health Connector",
        domain_name: "hbxshop.org",
        long_name: "Massachusetts Health Connector",
        copyright_period_start: '2018'
      }
      org_props = {
        _id: org_id,
        _type: "BenefitSponsors::Organizations::ExemptOrganization",
        dba: "CCA",
        fein: '123123456',
        hbx_id: '210005',
        legal_name: "Health Connector",
        site_id: site_id,
        profiles: [{
          _id: profile_id,
          contact_method: :paper_and_electronic,
          _type: "BenefitSponsors::Organizations::HbxProfile",
          cms_id: "MA0",
          us_state_abbreviation: "MA",
          is_benefit_sponsorship_eligible: true,
          office_locations: [{
            _id: office_location_id,
            is_primary: true,
            address: {
              _id: address_id,
              address_1: "1225 I St, NW",
              kind: "work",
              city: "Washington",
              state: "MA",
              zip: '20002',
            },
            phone: {
              _id: phone_id,
              kind: "main",
              area_code: '855',
              number: '5325465',
              full_phone_number: '8555325465'
            }
          }],
          inbox: { _id: inbox_id }
        }],
        site_owner_id: site_id
      }
      ::BenefitSponsors::Site.collection.insert_one(site_props)
      ::BenefitSponsors::Organizations::Organization.collection.insert_one(org_props)
      ::BenefitSponsors::Site.find(site_id)
    end
end
end
end