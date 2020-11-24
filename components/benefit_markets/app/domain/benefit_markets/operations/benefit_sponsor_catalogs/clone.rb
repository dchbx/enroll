# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitSponsorCatalogs
      # This class clones a benefit_sponsor_catalog where end
      # result is a new benefit_sponsor_catalog. Also, the result
      # benefit_sponsor_catalog is a non-persisted object.
      class Clone
        include Dry::Monads[:result, :do]

        # @param [ BenefitMarkets::BenefitSponsorCatalog ] benefit_sponsor_catalog
        # @return [ BenefitMarkets::BenefitSponsorCatalog ] benefit_sponsor_catalog
        def call(params)
          values                  = yield validate(params)
          benefit_sponsor_catalog = yield init_benefit_sponsor_catalog(values)

          Success(benefit_sponsor_catalog)
        end

        private

        def validate(params)
          return Failure('Missing Key.') unless params.key?(:benefit_sponsor_catalog)
          return Failure('Not a valid BenefitSponsorCatalog object.') unless params[:benefit_sponsor_catalog].is_a?(::BenefitMarkets::BenefitSponsorCatalog)

          Success(params)
        end

        def init_benefit_sponsor_catalog(values)
          current_bsc = values[:benefit_sponsor_catalog]
          new_bsc = ::BenefitMarkets::BenefitSponsorCatalog.new
          bsc_attributes = current_bsc.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :service_areas, :sponsor_market_policy, :member_market_policy, :product_packages)
          new_bsc.assign_attributes(bsc_attributes)
          assign_child_objects_for_bsc(new_bsc, current_bsc)
          Success(new_bsc)
        end

        def assign_child_objects_for_bsc(new_bsc, current_bsc)
          assign_service_areas(new_bsc, current_bsc)
          init_sponsor_market_policy(new_bsc, current_bsc) if current_bsc.sponsor_market_policy
          init_member_market_policy(new_bsc, current_bsc) if current_bsc.member_market_policy
          init_product_packages(new_bsc, current_bsc)
        end

        def assign_service_areas(new_bsc, current_bsc)
          new_bsc.service_areas = current_bsc.service_areas
        end

        def init_sponsor_market_policy(new_bsc, current_bsc)
          new_smp = new_bsc.build_sponsor_market_policy
          smp_params = current_bsc.sponsor_market_policy.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
          new_smp.assign_attributes(smp_params)
          new_smp
        end

        def init_member_market_policy(new_bsc, current_bsc)
          new_mmp = new_bsc.build_member_market_policy
          mmp_params = current_bsc.member_market_policy.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
          new_mmp.assign_attributes(mmp_params)
          new_mmp
        end

        def init_product_packages(new_bsc, current_bsc)
          current_bsc.product_packages.each do |current_pp|
            new_pp = new_bsc.product_packages.new
            pp_params = current_pp.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :products, :contribution_model, :assigned_contribution_model, :contribution_models, :pricing_model)
            new_pp.assign_attributes(pp_params)
            assign_child_objects_for_pp(new_pp, current_pp)
          end
        end

        def assign_child_objects_for_pp(new_pp, current_pp)
          init_products(new_pp, current_pp)
          init_contribution_model(new_pp, current_pp)
          init_assigned_contribution_model(new_pp, current_pp) if current_pp.assigned_contribution_model
          init_contribution_models(new_pp, current_pp)
          init_pricing_model(new_pp, current_pp)
        end

        def init_products(new_pp, current_pp)
          new_products = current_pp.products.inject([]) do |products_array, current_product|
            new_product = init_product(new_pp, current_product)
            product_params = current_product.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
            new_product.assign_attributes(product_params)
            assign_child_objects_for_product(new_product, current_product)
            products_array << new_product
          end

          new_pp.products = new_products
        end

        def init_product(new_pp, current_product)
          if current_product.health?
            ::BenefitMarkets::Products::HealthProducts::HealthProduct.new
          elsif current_product.dental?
            ::BenefitMarkets::Products::DentalProducts::DentalProduct.new
          else
            new_pp.products.new
          end
        end

        def assign_child_objects_for_product(new_product, current_product)
          init_sbc_document(new_product, current_product) if current_product.sbc_document
          init_premium_tables(new_product, current_product)
        end

        def init_sbc_document(new_product, current_product)
          new_sbc = new_product.build_sbc_document
          sbc_params = current_product.sbc_document.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
          new_sbc.assign_attributes(sbc_params)
        end

        def init_premium_tables(new_product, current_product)
          current_product.premium_tables.each do |current_premium_table|
            new_premium_table = new_product.premium_tables.new
            pt_params = current_premium_table.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :rating_area, :premium_tuples)
            new_premium_table.assign_attributes(pt_params)
            new_premium_table.rating_area = current_premium_table.rating_area
            init_premium_tuples(new_premium_table, current_premium_table)
          end
        end

        def init_premium_tuples(new_premium_table, current_premium_table)
          current_premium_table.premium_tuples.each do |premium_tuple|
            new_premium_tuple = new_premium_table.premium_tuples.new
            pt_params = premium_tuple.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
            new_premium_tuple.assign_attributes(pt_params)
          end
        end

        def init_contribution_model(new_pp, current_pp)
          new_cm = new_pp.build_contribution_model
          assign_contribution_model_params(new_cm, current_pp.contribution_model)
          init_contribution_units(new_cm, current_pp.contribution_model)
          new_cm
        end

        def init_assigned_contribution_model(new_pp, current_pp)
          new_acm = new_pp.build_assigned_contribution_model
          assign_contribution_model_params(new_acm, current_pp.assigned_contribution_model)
          new_acm
        end

        def init_contribution_models(new_pp, current_pp)
          current_pp.contribution_models.each do |contribution_model|
            new_cm = new_pp.contribution_models.new
            assign_contribution_model_params(new_cm, contribution_model)
          end
        end

        def assign_contribution_model_params(new_cm, current_cm)
          cm_params = current_cm.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :contribution_units, :member_relationships)
          new_cm.assign_attributes(cm_params)
          assign_child_objects_for_cm(new_cm, current_cm)
        end

        def assign_child_objects_for_cm(new_cm, current_cm)
          init_contribution_units(new_cm, current_cm)
          init_member_relationships(new_cm, current_cm)
        end

        def init_contribution_units(new_cm, current_cm)
          new_contribution_units = current_cm.contribution_units.inject([]) do |cus_array, contribution_unit|
            new_cu = init_contribution_unit(contribution_unit, new_cm)
            cu_params = contribution_unit.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :member_relationship_maps)
            new_cu.assign_attributes(cu_params)
            init_member_relationship_maps(new_cu, contribution_unit)
            cus_array << new_cu
          end

          new_cm.contribution_units = new_contribution_units
        end

        def init_contribution_unit(current_cu, new_cm)
          if current_cu._type.present?
            current_cu._type.constantize.new
          else
            new_cm.contribution_units.new
          end
        end

        def init_member_relationship_maps(new_cu, current_cu)
          current_cu.member_relationship_maps.each do |mrm|
            new_mrm = new_cu.member_relationship_maps.new
            mrm_params = mrm.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
            new_mrm.assign_attributes(mrm_params)
          end
        end

        def init_pricing_model(new_pp, current_pp)
          new_pm = new_pp.build_pricing_model
          pm_params = current_pp.pricing_model.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :member_relationships, :pricing_units)
          new_pm.assign_attributes(pm_params)
          assign_child_objects_for_pm(new_pm, current_pp.pricing_model)
          new_pm
        end

        def assign_child_objects_for_pm(new_pm, current_pm)
          init_member_relationships(new_pm, current_pm)
          init_pricing_units(new_pm, current_pm)
        end

        def init_member_relationships(new_parent, current_parent)
          current_parent.member_relationships.each do |member_relationship|
            new_mr = new_parent.member_relationships.new
            mr_params = member_relationship.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
            new_mr.assign_attributes(mr_params)
          end
        end

        def init_pricing_units(new_pm, current_pm)
          new_pricing_units = current_pm.pricing_units.inject([]) do |pus_array, pricing_unit|
            new_pu = init_pricing_unit(new_pm, pricing_unit)
            pu_params = pricing_unit.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
            new_pu.assign_attributes(pu_params)
            pus_array << new_pu
          end
          new_pm.pricing_units = new_pricing_units
        end

        def init_pricing_unit(new_pm, pricing_unit)
          if pricing_unit._type.present?
            pricing_unit._type.constantize.new
          else
            new_pm.pricing_units.new
          end
        end
      end
    end
  end
end
