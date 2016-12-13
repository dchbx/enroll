module Exchanges::HbxSettingsHelper

  def setting(property)
    group_id, attribute_id = property.to_s.split(".")
    if group_id.present?
      group = Settings.send(group_id) || []
binding.pry
      if group.size > 0 && attribute_id.present?
        group.select { |setting| setting[:id] == attribute_id.to_sym }
      else
        return group
      end
    end
  end

  def setting_value(property)
    # setting(property)
  end

end
