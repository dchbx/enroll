# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class ProductSummarySerializer
      include FastJsonapi::ObjectSerializer

      attributes :visit_type, :copay_in_network_tier_1, :copay_out_of_network

      attribute :service_header do |object|
        retrieve_info(object.visit_type)
      end

      SERVICES_YOU_MAY_NEED = {
        "Doctor Visits" =>
          [
            "Primary Care Visit to Treat an Injury or Illness",
            "Specialist Visit",
            "Other Practitioner Office Visit (Nurse, Physician Assistant)",
            "Prenatal and Postnatal Care",
            "Well Baby Visits and Care",
            "Preventative Care/Screening/Immunization",
            "Allergy Testing"
          ],

        "Testing and Imaging" =>
          [
            "X-rays and Diagnostic Imaging",
            "Laboratory Outpatient and Professional Services"
          ],

        "Prescription Drugs" =>
          [
            "Separate Drug Deductible",
            "Generic Drugs",
            "Preferred Brand Drugs",
            "Non-Preferred Brand Drugs",
            "Specialty Drugs"
          ],

        "Emergency" =>
          [
            "Emergency Room Services",
            "Emergency Medical Transportation/Ambulance",
            "Urgent Care Centers or Facilities"
          ],

        "Hospital" =>
          [
            "Inpatient Hospital Services (e.g. Hospital Stay)",
            "Inpatient Physician and Surgical Services",
            "Outpatient Facility Fee (e.g. Ambulatory Surgery Center)",
            "Outpatient Surgery Physician/Surgical Services",
            "Delivery and All inpatient Services for Maternity Care"
          ],

        "Mental/Behavioral Health" =>
          [
            "Mental/Behavioral Health Inpatient Services",
            "Mental/Behavioral health Outpatient Services",
            "Substance Abuse Disorder Inpatient Services",
            "Substance Abuse Disorder Outpatient Services",
            "Outpatient Rehabilitation Services"
          ],

        "Vision and Dental" =>
          [
            "Child - Routine Eye Exam",
            "Child - Eye Glasses",
            "Child - Dental Check-up",
            "Child - Basic Dental Care",
            "Child - Major Dental Care",
            "Child - Orthodontia",
            "Adult - Routine Eye Exam",
            "Accidental Dental"
          ],

        "Other Services" =>
          [
            "Nutritional Counseling",
            "Diabetes Eductation",
            "Treatment for Temporomandibular Joint Disorders",
            "Chiropractic Care",
            "Dialysis",
            "Rehabilitative Speech Therapy",
            "Rehabilitative Occupational and Rehabilitative Physical Therapy",
            "Habilitation Services",
            "Home Health Care Services",
            "Skilled Nursing Facility",
            "Hospice Services",
            "Chemotherapy",
            "Radiation",
            "Infusion Therapy",
            "Transplant",
            "Reconstructive Surgery",
            "Durable Medical Equipment",
            "Prosthetic Devices",
            "Abortion for Which Public Funding is Prohibited"
          ]
      }.freeze

      class << self
        def retrieve_info(visit_type)
          SERVICES_YOU_MAY_NEED.select{|_key, array| array.include? visit_type }.keys.first
        end
      end
    end
  end
end
