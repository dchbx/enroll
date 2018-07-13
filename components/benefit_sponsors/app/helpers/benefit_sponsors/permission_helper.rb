module BenefitSponsors
  module PermissionHelper
    def policy_helper pundit_object
      policy(pundit_object)
    end

    def pundit_span pundit_object, pundit_method
      result = policy_helper(pundit_object).send(pundit_method) ? '<span class="no-op">' : ' <span class="blocking" >'
      raw result
    end

    def pundit_class pundit_object, pundit_method
      result = policy_helper(pundit_object).send(pundit_method) ? ' no-op ' : '  blocking '
      raw result
    end

    def pundit_allow pundit_object, pundit_method
      result = policy_helper(pundit_object).send(pundit_method)
    end
  end
end
