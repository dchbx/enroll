require 'rails_helper'

module BenefitMarkets
  module Forms
    RSpec.describe BenefitMarket, type: :model, dbclean: :after_each do
      shared_context "params", :shared_context => :metadata do
        let(:params) do
          {
            "site_urn"=>"DC",
            "title"=>"ACA",
            "description"=>"Test",
            "kind"=>"aca_individual",
            "aca_individual_configuration"=>{ "mm_enr_due_on"=>"15",
              "vr_os_window"=>"0",
              "vr_due"=>"95",
              "open_enrl_start_on"=>"2017-11-01",
              "open_enrl_end_on"=>"2017-01-31",
              "initial_application_configuration"=>{ "pub_due_dom"=>"5",
                "erlst_strt_prior_eff_months"=>"-3",
                "appeal_per_aft_app_denial_dys"=>"30",
                "quiet_per_end"=>"28",
                "inelig_per_aft_app_denial_dys"=>"90" } },
            "aca_shop_configuration"=>{ "ee_ct_max"=>"50",
              "ee_ratio_min"=>"0.666",
              "ee_non_owner_ct_min"=>"1",
              "er_contrib_pct_min"=>"75",
              "binder_due_dom"=>"",
              "erlst_e_prior_eod"=>"-30",
              "ltst_e_aft_eod"=>"30",
              "ltst_e_aft_ee_roster_cod"=>"30",
              "retroactve_covg_term_max_dys"=>"-60",
              "ben_per_min_year"=>"1",
              "ben_per_max_year"=>"1",
              "oe_start_month"=>"1",
              "oe_end_month"=>"10",
              "oe_min_dys"=>"5",
              "oe_grce_min_dys"=>"5",
              "oe_min_adv_dys"=>"5",
              "oe_max_months"=>"2",
              "cobra_epm"=>"6",
              "gf_new_enrollment_trans"=>"16",
              "gf_update_trans_dow"=>"Friday",
              "use_simple_er_cal_model"=>"true",
              "offerings_constrained_to_service_areas"=>"false",
              "trans_er_immed"=>"false",
              "trans_scheduled_er"=>"true",
              "er_transmission_dom"=>"16",
              "enforce_er_attest"=>"false",
              "stan_indus_class"=>"false",
              "carrier_filters_enabled"=>"false",
              "rating_areas"=>"",
              "initial_application_configuration"=>{"pub_due_dom"=>"10",
                "erlst_strt_prior_eff_months"=>"-3",
                "appeal_per_aft_app_denial_dys"=>"30",
                "quiet_per_end"=>"28",
                "inelig_per_aft_app_denial_dys"=>"90"},
              "renewal_application_configuration"=>{"erlst_strt_prior_eff_months"=>"-3",
                "montly_oe_end"=>"13",
                "pub_due_dom"=>"15",
                "force_pub_dom"=>"11",
                "oe_min_dys"=>"3",
                "quiet_per_end"=>"15"} }
          }
        end
      end

      let(:site) { create :benefit_sponsors_site, :with_owner_exempt_organization }

      describe '##for_new' do
        subject { BenefitMarkets::Forms::BenefitMarket.for_new }
        it 'instantiates a new Benefit Market Form' do
          expect(subject).to be_an_instance_of(BenefitMarkets::Forms::BenefitMarket)
        end

        it 'the Benefit Market Form has an ACA Shop Configuration' do
          expect(subject.aca_shop_configuration).to be_an_instance_of(BenefitMarkets::Forms::AcaShopConfiguration)
        end

        it 'the Benefit Market Form has an ACA Individual Configuration' do
          expect(subject.aca_individual_configuration).to be_an_instance_of(BenefitMarkets::Forms::AcaIndividualConfiguration)
        end
      end

      describe '##for_create' do
        include_context 'params'

        subject { BenefitMarkets::Forms::BenefitMarket.for_create params }

        it 'instantiates a new Benefit Market Form with the correct variables' do
          expect(subject.site_urn).to eql('DC')
        end

        it 'creates a new BenfitSponsors::Site when saved' do
          expect { subject.save }.to change { BenefitMarkets::BenefitMarket.count }.by(1)
        end
      end

      describe '##for_edit' do
        let(:benefit_market) { create :benefit_markets_benefit_market }

        subject { BenefitMarkets::Forms::BenefitMarket.for_edit benefit_market.id.to_s }

        it 'loads the existing Site in to the Site Form' do
          expect(subject.title).to eql(benefit_market.title)
        end

        it 'loads the aca shop initial application configuration' do
          expect(subject.aca_shop_configuration.initial_application_configuration.pub_due_dom).to eql(benefit_market.configuration.initial_application_configuration.pub_due_dom)
        end
      end

      describe '##for_update' do
        include_context 'params'

        let(:benefit_market) { create :benefit_markets_benefit_market }

        subject { BenefitMarkets::Forms::BenefitMarket.for_update benefit_market.id.to_s }

        it 'loads the existing Site in to the Site Form' do
          expect(subject.title).to eql(benefit_market.title)
        end

        it 'loads the aca shop initial application configuration' do
          expect(subject.aca_shop_configuration.initial_application_configuration.pub_due_dom).to eql(benefit_market.configuration.initial_application_configuration.pub_due_dom)
        end

        context '#updates_attributes' do
          before do
            subject.update_attributes params
            benefit_market.reload
          end

          it "updates the db model's title" do
            expect(benefit_market.title).to eql(params['title'])
          end

          it "updates the form's title" do
            expect(subject.title).to eql(params['title'])
          end

          it 'updates the configuration' do
            expect(subject.aca_shop_configuration.initial_application_configuration.pub_due_dom).to eql(10) # set manually params line 52
          end
        end
      end
    end
  end
end
