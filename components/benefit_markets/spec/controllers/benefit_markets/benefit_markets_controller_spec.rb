require 'rails_helper'

module BenefitMarkets
  RSpec.describe BenefitMarkets::BenefitMarketsController, type: :controller, dbclean: :after_each do
    shared_context "params", :shared_context => :metadata do
      let(:valid_params) do
        {
          'site_urn'=>'DC',
          'title'=>'ACA',
          'description'=>'Test',
          'kind'=>'aca_individual',
          'aca_individual_configuration'=>{ 'mm_enr_due_on'=>'15',
            'vr_os_window'=>'0',
            'vr_due'=>'95',
            'open_enrl_start_on'=>'2017-11-01',
            'open_enrl_end_on'=>'2017-01-31',
            'initial_application_configuration'=>{ 'pub_due_dom'=>'5',
              'erlst_strt_prior_eff_months'=>'-3',
              'appeal_per_aft_app_denial_dys'=>'30',
              'quiet_per_end'=>'28',
              'inelig_per_aft_app_denial_dys'=>'90' } },
          'aca_shop_configuration'=>{ 'ee_ct_max'=>'50',
            'ee_ratio_min'=>'0.666',
            'ee_non_owner_ct_min'=>'1',
            'er_contrib_pct_min'=>'75',
            'binder_due_dom'=>'',
            'erlst_e_prior_eod'=>'-30',
            'ltst_e_aft_eod'=>'30',
            'ltst_e_aft_ee_roster_cod'=>'30',
            'retroactve_covg_term_max_dys'=>'-60',
            'ben_per_min_year'=>'1',
            'ben_per_max_year'=>'1',
            'oe_start_month'=>'1',
            'oe_end_month'=>'10',
            'oe_min_dys'=>'5',
            'oe_grce_min_dys'=>'5',
            'oe_min_adv_dys'=>'5',
            'oe_max_months'=>'2',
            'cobra_epm'=>'6',
            'gf_new_enrollment_trans'=>'16',
            'gf_update_trans_dow'=>'Friday',
            'use_simple_er_cal_model'=>'true',
            'offerings_constrained_to_service_areas'=>'false',
            'trans_er_immed'=>'false',
            'trans_scheduled_er'=>'true',
            'er_transmission_dom'=>'16',
            'enforce_er_attest'=>'false',
            'stan_indus_class'=>'false',
            'carrier_filters_enabled'=>'false',
            'rating_areas'=>'',
            'initial_application_configuration'=>{'pub_due_dom'=>'10',
              'erlst_strt_prior_eff_months'=>'-3',
              'appeal_per_aft_app_denial_dys'=>'30',
              'quiet_per_end'=>'28',
              'inelig_per_aft_app_denial_dys'=>'90'},
            'renewal_application_configuration'=>{'erlst_strt_prior_eff_months'=>'-3',
              'montly_oe_end'=>'13',
              'pub_due_dom'=>'15',
              'force_pub_dom'=>'11',
              'oe_min_dys'=>'3',
              'quiet_per_end'=>'15'} }
        }
      end

      let(:invalid_params) { valid_params.merge('title' => '') }
    end

    routes { BenefitMarkets::Engine.routes }

    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }

    # let!(:site) { create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, kind: 'aca_shop') }

    describe "GET new", dbclean: :after_each do
      before do
        get :new, :site_id => site.id
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render new template" do
        expect(response).to render_template("new")
      end
    end

    describe "POST create", dbclean: :after_each do
      include_context 'params'

      context 'with valid params' do
        before do
          post :create, :site_id => site.id, :benefit_market => valid_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end
      end

      context "with invalid params" do
        before do
          post :create, :site_id => site.id, :benefit_market => invalid_params
        end

        it "re-renders new" do
          expect(response).to render_template("new")
        end

        it "returns error messages" do
          expect(assigns(:benefit_market).errors.messages).to include(title: ["can't be blank"])
        end
      end

    end

    describe "GET edit" do
      let(:benefit_market) { FactoryGirl.create(:benefit_markets_benefit_market, site: site) }

      before do
        put :edit, :id => benefit_market.id
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render edit template" do
        expect(response).to render_template("edit")
      end
    end

    describe "POST update" do
      include_context 'params'

      let(:benefit_market) { FactoryGirl.create(:benefit_markets_benefit_market, site: site) }

      context "with valid params" do
        before do
          patch :update, :id => benefit_market.id, :benefit_market => valid_params
        end

        it "should redirect to site benefit markets index" do
          expect(response).to redirect_to(site_benefit_markets_path(site))
        end
      end

      context "when update fails" do
        before do
          patch :update, :id => benefit_market.id, :benefit_market => invalid_params
        end

        it "should redirect to edit" do
          expect(response).to render_template("edit")
        end

        it "returns error messages" do
          expect(assigns(:benefit_market).errors.messages).to include(title: ["can't be blank"])
        end
      end
    end
  end
end
