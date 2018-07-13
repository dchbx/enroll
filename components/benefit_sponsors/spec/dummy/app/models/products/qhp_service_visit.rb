class Products::QhpServiceVisit
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp_cost_share_variance

  field :visit_type, type: String
  field :copay_in_network_tier_1, type: String
  field :copay_in_network_tier_2, type: String
  field :copay_out_of_network, type: String
  field :co_insurance_in_network_tier_1, type: String
  field :co_insurance_in_network_tier_2, type: String
  field :co_insurance_out_of_network, type: String

## Service visit types
# visit_type: "Maximum Out of Pocket for Medical EHB Benefits"
# visit_type: "Maximum Out of Pocket for Drug EHB Benefits"
# visit_type: "Maximum Out of Pocket for Medical and Drug EHB Benefits (Total)"
# visit_type: "Medical EHB Deductible"
# visit_type: "Drug EHB Deductible"
# visit_type: "Combined Medical and Drug EHB Deductible"
# visit_type: "Subgroup - Pediatric Dental"
# visit_type: "Primary Care Visit to Treat an Injury or Illness"
# visit_type: "Specialist Visit"
# visit_type: "Outpatient Facility Fee (e.g.,  Ambulatory Surgery Center)"
# visit_type: "Outpatient Surgery Physician/Surgical Services"
# visit_type: "Hospice Services"
# visit_type: "Non-Emergency Care When Traveling Outside the U.S."
# visit_type: "Routine Dental Services (Adult)"
# visit_type: "Long-Term/Custodial Nursing Home Care"
# visit_type: "Routine Eye Exam (Adult)"
# visit_type: "Urgent Care Centers or Facilities"
# visit_type: "Home Health Care Services"
# visit_type: "Emergency Room Services"
# visit_type: "Emergency Transportation/Ambulance"
# visit_type: "Inpatient Hospital Services (e.g., Hospital Stay)"
# visit_type: "Inpatient Physician and Surgical Services"
# visit_type: "Skilled Nursing Facility"
# visit_type: "Prenatal and Postnatal Care"
# visit_type: "Delivery and All Inpatient Services for Maternity Care"
# visit_type: "Mental/Behavioral Health Outpatient Services"
# visit_type: "Mental/Behavioral Health Inpatient Services"
# visit_type: "Substance Abuse Disorder Outpatient Services"
# visit_type: "Substance Abuse Disorder Inpatient Services"
# visit_type: "Generic Drugs"
# visit_type: "Preferred Brand Drugs"
# visit_type: "Non-Preferred Brand Drugs"
# visit_type: "Specialty Drugs"
# visit_type: "Outpatient Rehabilitation Services"
# visit_type: "Habilitation Services"
# visit_type: "Chiropractic Care"
# visit_type: "Durable Medical Equipment"
# visit_type: "Imaging (CT/PET Scans, MRIs)"
# visit_type: "Preventive Care/Screening/Immunization"
# visit_type: "Weight Loss Programs"
# visit_type: "Routine Eye Exam for Children"
# visit_type: "Eye Glasses for Children"
# visit_type: "Dental Check-Up for Children"
# visit_type: "Rehabilitative Speech Therapy"
# visit_type: "Rehabilitative Occupational and Rehabilitative Physical Therapy"
# visit_type: "Well Baby Visits and Care"
# visit_type: "Laboratory Outpatient and Professional Services"
# visit_type: "X-rays and Diagnostic Imaging"
# visit_type: "Basic Dental Care - Child"
# visit_type: "Orthodontia - Child"
# visit_type: "Major Dental Care - Child"
# visit_type: "Abortion for Which Public Funding is Prohibited"
# visit_type: "Transplant"
# visit_type: "Accidental Dental"
# visit_type: "Dialysis"
# visit_type: "Allergy Testing"
# visit_type: "Chemotherapy"
# visit_type: "Radiation"
# visit_type: "Diabetes Education"
# visit_type: "Prosthetic Devices"
# visit_type: "Infusion Therapy"
# visit_type: "Treatment for Temporomandibular Joint Disorders"
# visit_type: "Nutritional Counseling"
# visit_type: "Reconstructive Surgery"
# visit_type: "Clinical Trials"
# visit_type: "Diabetes Care Management"
# visit_type: "Prescription Drugs Other"

end
