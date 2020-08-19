module NavigationHelper
  def tell_us_about_yourself_active?
    return true if controller_name == "consumer_roles" && ['edit', 'ridp_agreement'].include?(action_name)
    return true if controller_name == "interactive_identity_verifications"
    return true if ["help_paying_coverage", "application_checklist"].include?(action_name)
    return true if controller_name == "family_members" && action_name == "index"
    return true if controller_name == "family_relationships" && action_name == "index"
  end

  def account_registration_active?
    ["search", "match"].include?(action_name)
  end

  def tell_us_about_yourself_current_step?
    return true if controller_name == "consumer_roles" && ['edit', 'ridp_agreement'].include?(action_name)
    return true if controller_name == "interactive_identity_verifications"
    return true if ["help_paying_coverage", "application_checklist"].include?(action_name)
  end

  def family_members_index_active?
	return true if controller_name == "family_members" && action_name == "index"
	return true if controller_name == "family_relationships" && action_name == "index"
  end

  def family_members_index_current_step?
	return true if controller_name == "family_relationships" && action_name == "index"
	return true if controller_name == "family_members" && action_name == "index"
  end
end
