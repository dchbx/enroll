module BenefitMarkets
  module RulesEngine
    class BenefitSponsorEligibilityPolicy
      include BenefitMarkets::BusinessRulesEngine

      rule  :initial_sponsor,
        validate: ->(sponsor){ 
          [:initial, :off_cycle_renewal].include?(sponsor.benefit_type)
        },
        success:  ->(sponsor){ 'validated successfully' }

      rule  :renewal_sponsor,
        validate: ->(sponsor){
          [:renewal].include?(sponsor.benefit_type)
        },
        success:  ->(sponsor){ 'validated successfully' }
      
      rule  :effective_date_jan,
        validate: ->(sponsor){
          sponsor.effective_date.yday == 1
        },
        success:  ->(sponsor){ 'validated successfully' }
      
      rule  :effective_date_feb_dec,
        validate: ->(sponsor){
          (2..12).include?(sponsor.effective_date.month)
        },
        success:  ->(sponsor){ 'validated successfully' }


      business_policy :initial_sponsor_default, commands: [:create_application], rules: [:initial_sponsor, :effective_date_feb_dec], policy_result: :zero_pct_sponsor_fixed_pct_contribution_model
      business_policy :renewal_sponsor_default, commands: [:create_application], rules: [:renewal_sponsor, :effective_date_feb_dec], policy_result: :fifty_pct_sponsor_fixed_pct_contribution_model

      business_policy :initial_sponsor_jan_default, commands: [:create_application], rules: [:initial_sponsor, :effective_date_jan], policy_result: :zero_pct_sponsor_fixed_pct_contribution_model
      business_policy :renewal_sponsor_jan_default, commands: [:create_application], rules: [:renewal_sponsor, :effective_date_jan], policy_result: :zero_pct_sponsor_fixed_pct_contribution_model

      business_policy :renewal_sponsor_with_exception, commands: [:create_application], rules: [:renewal_sponsor]
      # business_policy  :contribution_model_assignment,  commands: [:create_sponsor_catalog], rules: [:effective_date, :enrollment_type]

      # ContribuionModel
      # field :contribution_type, type: Symbol (:aca_flexible / :hbx_standard)
      # field :effective_period,  type: Range
      # field :eligibility_policies, type: Array

      
      # 2020 contribution models:
      # ---------------------------
      
      #   aca_flexible_contribution_model 
      #     - :initial_sponsor_within_effective_period
      #     - :renewal_sponsor_within_effective_period
      
      #   hbx_flexible_contribution_model 
      #     - :initial_sponsor_within_effective_period
      #     - :renewal_sponsor_with_exception_within_effective_period
      
      #   hbx_standard_contribution_model 
      #     - :renewal_sponsor_without_exception_within_effective_period
      

      # 2021 contribution models:
      # ---------------------------
      
      #   aca_flexible_contribution_model 
      #     - :initial_sponsor_within_effective_period
      #     - :renewal_sponsor_within_effective_period
      
      #   hbx_flexible_contribution_model 
      #     - :initial_sponsor_with_exception_within_effective_period
      #     - :renewal_sponsor_with_exception_within_effective_period
      
      #   hbx_standard_contribution_model 
      #     - :initial_sponsor_without_exception_within_effective_period
      #     - :renewal_sponsor_without_exception_within_effective_period



      #    BenefitMarketCatalog
      #      - business policies   =>  BenefitSponsorCatalog

      #    -> business_policies extended to have commands(equavalent to aasm transition). commands will be used to filter business
      #    policies that are relavant for the command

      #       may be add monads to business policies? 

      #    -> business policies are like guards on the aasm transition
      #    -> commands are like aasm state transitions
       
      #    -> BenefitSponsorCatalog factory will copy policies along with new contribution models
      #       -> designate default contribution model 

      #    -> BenefitPackage Create/Sponsored Benefit Create 
      #       -> fetch product package from benefit sponsor catalog 
      #       -> they build contribution model ??


      # - benefit_market
      #   - benefit_market_catalog
      #     - business_policy_packages (aka business_policies)
      #     - product_packages
      #       - contribution_model
      #       - contribution_models




      # initial/renewal 
      # list_bill/sole_source/fixed caps
      # health/dental


      # rule :zero_pct_contribution_employee
      # rule :fifty_pct_contribution_employee
      # rule :effective_date_jan
      # rule :effective_date_feb_dec
      # rule :initial_sponsor
      # rule :renewal_sponsor
      # rule :exception_granted

      # rule :zero_participation # same as not applying rule
      # rule :two_third_participation
      # rule :atleast_one_non_owner_enrolled


      # business_policy :initial_sponsor_default,        command: [:create_application], rules: [:initial_sponsor, :zero_pct_contribution_employee]
      # business_policy :renewal_sponsor_default,        command: [:create_application], rules: [:renewal_sponsor, :fifty_pct_contribution_employee], event:
      # business_policy :renewal_sponsor_with_exception, command: [:create_application], rules: [:renewal_sponsor, :fifty_pct_contribution_employee, :exception_granted], event:
      # business_policy :renewal_sponsor_jan_default,    command: [:create_application], rules: [:effective_date_jan, :renewal_sponsor, :zero_pct_contribution_employee], event:


      # business_policy :initial_sponsor, command: [:benefit_application, :close_open_enrollment], rules: [:effective_date_jan, :renewal_sponsor, :zero_pct_contribution_employee], event:
      # business_policy :renewal_sponsor, command: [:close_open_enrollment], rules: [:effective_date_jan, :renewal_sponsor, :zero_pct_contribution_employee], event:


      # rule  :validate_initial_sponsor,
      #   validate: ->(sponsor){ 
      #     [:initial, :off_cycle_renewal].include?(sponsor.benefit_type)
      #   },
      #   success:  ->(sponsor){ 'validated successfully' }

      # rule  :validate_renewal_sponsor,
      #   validate: ->(sponsor){
      #     [:renewal].include?(sponsor.benefit_type)
      #   },
      #   success:  ->(sponsor){ 'validated successfully' }
      
      # rule  :effective_period_rule,
      #   validate: ->(sponsor){
      #     sponsor.contribution_model.effective_period.cover?(sponsor.effective_date)
      #   },
      #   success:  ->(sponsor){ 'validated successfully' }
      
      # rule  :exception_rule,
      #   validate: ->(sponsor){
      #     sponsor.exception_granted
      #   },
      #   success:  ->(sponsor){ 'validated successfully' }
      
      # rule  :no_exception_rule,
      #   validate: ->(sponsor){
      #     !sponsor.exception_granted
      #   },
      #   success:  ->(sponsor){ 'validated successfully' }
      

      # business_policy :initial_sponsor_within_effective_period, rules: [:validate_initial_sponsor, :effective_period_rule]
      # business_policy :renewal_sponsor_within_effective_period, rules: [:validate_renewal_sponsor, :effective_period_rule]
      # business_policy :initial_sponsor_with_exception_within_effective_period, rules: [:validate_initial_sponsor, :exception_rule, :effective_period_rule]
      # business_policy :renewal_sponsor_with_exception_within_effective_period, rules: [:validate_renewal_sponsor, :exception_rule, :effective_period_rule]
      # business_policy :initial_sponsor_without_exception_within_effective_period, rules: [:validate_initial_sponsor, :no_exception_rule, :effective_period_rule]
      # business_policy :renewal_sponsor_without_exception_within_effective_period, rules: [:validate_renewal_sponsor, :no_exception_rule, :effective_period_rule]       
    
      # def business_policy_for?(policy_name)
      #   business_policies[policy_name.to_sym]
      # end

      def business_policies_for(command)
        [].tap do |policies|
          business_policies.each do |name, policy|
            policies << policy if policy.commands.include?(command.to_sym)
          end
        end
      end
    end
  end
end
