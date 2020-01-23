# Business rules governing ACA SHOP BenefitApplication and associated work flow processes.
# BenefitApplication business rules are checked at two separate steps during the enrollment process:
#
# 1) Application is submitted: are application criteria satisfied to proceed with open enrollment?
# 2) Open enrollment ends: are enrollment criteria satisfied to proceed with benefit coverage?
#
# Note about difference between business and data integrity rules:
#
# Business rules and policies managed by the Exchange Administrator belong here, in the domain logic
# tier of the application. Under special circumstances, these business rules may be applied differently
# or relaxed to handle exceptions, recover from errors, etc.
#
# In contrast, data integrity and data association rules belong in the model tier of the application.
# Those rules are necessary to ensure proper system function and are thus inviolable.  If you encounter
# data model validation or verification errors during development, it likely indicates that you are
# violating a design rule and should seek advice on proper approch to perform the necessary activity.
module BenefitSponsors
  class BenefitApplications::AcaShopEnrollmentEligibilityPolicy
    include BenefitMarkets::BusinessRulesEngine

    # ENROLLMENT_RATIO_MINIMUM = 0.75
    rule  :minimum_participation_rule,
            # validate: ->(benefit_application){ benefit_application.enrollment_ratio >= ENROLLMENT_RATIO_MINIMUM },
            validate: ->(benefit_application){benefit_application.enrollment_ratio >= benefit_application.employee_participation_ratio_minimum },
            success:  ->(benefit_application){"validated successfully"},
            fail:     ->(benefit_application){"Number of eligible members enrolling: (#{benefit_application.total_enrolled_count}) is less than minimum required: #{benefit_application.eligible_to_enroll_count * benefit_application.employee_participation_ratio_minimum}" }

    rule  :non_business_owner_enrollment_count,
            validate: ->(benefit_application){
                            benefit_application.non_business_owner_enrolled.count <= benefit_application.eligible_to_enroll_count &&
                            benefit_application.non_business_owner_enrolled.count >= Settings.aca.shop_market.non_owner_participation_count_minimum.to_f
                          },
            success:  ->(benefit_application){"validated successfully"},
            fail:     ->(benefit_application){"At least #{Settings.aca.shop_market.non_owner_participation_count_minimum.to_f} non-owner employee must enroll" }

    rule :minimum_eligible_member_count,
            validate: ->(benefit_application){ benefit_application.eligible_to_enroll_count > 0 },
            success:  ->(benefit_application){"validated successfully"},
            fail:     ->(benefit_application){"At least one member must be eligible to enroll" }

    business_policy :enrollment_elgibility_policy,
                    rules: [:minimum_participation_rule, :non_business_owner_enrollment_count, :minimum_eligible_member_count]

    # For 1/1 effective date minimum participation rule does not apply
    # 1+ non-owner rule does apply
    business_policy :non_minimum_participation_enrollment_eligiblity_policy,
                    rules: [:non_business_owner_enrollment_count, :minimum_eligible_member_count]


    def business_policies_for(model_instance, event_name)
      if model_instance.is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)
        case event_name
          when :end_open_enrollment
            enrollment_eligiblity_policy_for(model_instance)
          else
            enrollment_eligiblity_policy_for(model_instance)
        end
      end
    end

    private

    # Making the system to default to amnesty rules for release 1.
    def enrollment_eligiblity_policy_for(model_instance)
      business_policies[:non_minimum_participation_enrollment_eligiblity_policy]
      # if model_instance.start_on.yday == 1
      #   business_policies[:non_minimum_participation_enrollment_eligiblity_policy]
      # else
      #   business_policies[:enrollment_elgibility_policy]
      # end
    end
  end
end
