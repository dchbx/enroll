# frozen_string_literal: true

class ViewAdaComplianceLinter
  attr_accessor :stringified_view_files, :compliance_rules

  def initialize(stringified_view_files, compliance_rules)
    @stringified_view_files = stringified_view_files
    @compliance_rules = compliance_rules
  end

  def view_ada_compliant?
    required_unique_attributes_present?
    # image_alt_descriptions_present?
  end

  def required_unique_attributes_present?
    unique_html_attributes = compliance_rules['unique_html_attributes']
    return true if unique_html_attributes.blank?
    return true if stringified_view_files.blank?
    stringified_view_files.each do |filename, stringified_view|


    end
  end

  # TODO: This is part of the ADA rule of all link text being unique.
  # Find a way to integrate title element checks
  # Possibly can use strip_links helper
  # def links_have_unique_text?
  # end
end
