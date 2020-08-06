# frozen_string_literal: true

xml.instruct!
xml.benchmark_plan(:'xmlns:xs' => "http://www.w3.org/2001/XMLSchema",
                   :xmlns => "http://openhbx.org/api/terms/1.0") do
  xml.id do
    xml.id @plan.hios_id
  end
  xml.name @plan.name
  xml.active_year @plan.active_year
  xml.is_dental_only @plan.is_dental_only?
  xml.carrier do
    xml.id do
      xml.id @plan.carrier_profile.id
    end
    xml.name @plan.carrier_profile.legal_name
    xml.is_active @plan.carrier_profile.is_active || true
  end
  xml.market "urn:openhbx:terms:v1:aca_marketplace##{@plan.market}"
  xml.metal_level "urn:openhbx:terms:v1:plan_metal_level##{@plan.metal_level}"
  xml.coverage_type "urn:openhbx:terms:v1:qhp_benefit_coverage##{@plan.coverage_kind}"
  xml.ehb_percent @plan.ehb * 100
end