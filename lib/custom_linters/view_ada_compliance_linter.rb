# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'

# This class will check for basic Americans with Disabilities Act (ADA) compliance
# TODO: Update with descriptive puts output messages
# TODO: Add more use cases
class ViewAdaComplianceLinter
  attr_accessor :stringified_view_files, :compliance_rules, :unique_html_attributes

  def initialize(stringified_view_files, compliance_rules)
    @stringified_view_files = stringified_view_files
    @compliance_rules = compliance_rules.with_indifferent_access
    @unique_html_attributes = compliance_rules.dig(:unique_html_attributes)
  end

  def view_to_nokogiri(stringified_view)
    Nokogiri::HTML(stringified_view)
  end

  def ada_violation_in_view(stringified_view)
    nokogiri_doc = view_to_nokogiri(stringified_view)
    # Will return violations as arrays
    elements_missing_unique_attributes(nokogiri_doc) +
    images_missing_alt_text(nokogiri_doc)
  end
  
  def views_ada_compliant?
    return true if stringified_view_files.blank?
    compliance_results = {}
    stringified_view_files.each do |view_filename, stringified_view|
      violations_in_view = ada_violation_in_view(stringified_view)
      if violations_in_view.present?
        compliance_results[view_filename] = violations_in_view
      end
    end
    compliance_results.blank?
  end

  def elements_missing_unique_attributes(nokogiri_doc)
    duplicated_elements = []
    return duplicated_elements if unique_html_attributes.blank?
    # TODO: Maybe need to do more than inputs
    doc_inputs = nokogiri_doc.css('input')
    unique_html_attributes.each do |attribute|
      attribute_values = doc_inputs.map { |input| input[attribute.to_sym] }
      next if attribute_values.compact.blank?
      next if attribute_values.uniq.size == attribute_values.size
      duplicated_elements << {attribute.to_sym => attribute_values}
    end
    duplicated_elements
  end

  def images_missing_alt_text(nokogiri_doc)
    alt_text_results = []
    nokogiri_imgs = nokogiri_doc.css('img')
    return alt_text_results if nokogiri_imgs.blank?
    nokogiri_imgs.each do |img|
      # blank? will return true on both "" or nil (nil if no alt is present)
      alt_text_results << img[:src] if img[:alt].blank?
    end
    alt_text_results
  end

  # TODO: This is part of the ADA rule of all link text being unique.
  # Find a way to integrate title element checks
  # Possibly can use strip_links helper
  # def links_have_unique_text?
  # end
end
