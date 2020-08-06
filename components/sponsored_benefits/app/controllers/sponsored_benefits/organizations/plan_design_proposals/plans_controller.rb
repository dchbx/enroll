# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlansController < ApplicationController

      def index
        offering_query = ::Queries::EmployerPlanOfferings.new(plan_design_organization)
        @plans = case selected_carrier_level
                 when "single_carrier"
                   offering_query.send "single_carrier_offered_#{kind}_plans", params[:carrier_id], params[:active_year]
                 when "metal_level"
                   offering_query.metal_level_offered_health_plans(params[:metal_level], params[:active_year])
                 when "single_plan"
                   offering_query.send "single_option_offered_#{kind}_plans", params[:carrier_id], params[:active_year]
                 when "sole_source"
                   offering_query.sole_source_offered_health_plans(params[:carrier_id], params[:active_year])
                 end
        @plans = @plans.select{|a| a.premium_tables.present?}
        @search_options = ::Plan.search_options(@plans)
        @search_option_titles = {
          'plan_type': Settings.aca.state_abbreviation == 'DC' ? 'Plan Type' : 'HMO / PPO',
          'plan_hsa': 'HSA - Compatible',
          'metal_level': 'Metal Level',
          'plan_deductible': 'Individual deductible (in network)'
        }
      end

      def dental_reference_plans
        offering_query = ::Queries::EmployerPlanOfferings.new(plan_design_organization)
        @plans = offering_query.dental_reference_plans_by_id(params[:plans_ids], params[:active_year])
        @plans = @plans.select{|a| a.premium_tables.present?}
        @search_options = ::Plan.search_options(@plans)
        @search_option_titles = {
          'plan_type': Settings.aca.state_abbreviation == 'DC' ? 'Plan Type' : 'HMO / PPO',
          'plan_hsa': 'HSA - Compatible',
          'metal_level': 'Metal Level',
          'plan_deductible': 'Individual deductible (in network)'
        }
      end

      private

      helper_method :selected_carrier_level, :plan_design_organization, :carrier_profile, :carriers_cache, :kind

      def selected_carrier_level
        @selected_carrier_level ||= params[:selected_carrier_level]
      end

      def plan_design_organization
        @plan_design_organization ||= PlanDesignOrganization.find(params[:plan_design_organization_id])
      end

      def carrier_profile
        @carrier_profile ||= ::CarrierProfile.find(params[:carrier_id])
      end

      def carriers_cache
        @carriers_cache ||= ::CarrierProfile.all.inject({}){|carrier_hash, carrier_profile| carrier_hash[carrier_profile.id] = carrier_profile.legal_name; carrier_hash; }
      end

      def kind
        params[:kind]
      end
    end
  end
end
