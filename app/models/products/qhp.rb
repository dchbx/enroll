class Products::Qhp
  include Mongoid::Document
  include Mongoid::Timestamps
  include CsvOperater

  field :template_version, type: String
  field :issuer_id, type: String
  field :state_postal_code, type: String
  field :state_postal_name, type: String
  field :market_coverage, type: String
  field :dental_plan_only_ind, type: String
  field :tin, type: String
  field :application_id, type: String

  # Standard component - 14 chars
  field :standard_component_id, type: String
  field :plan_marketing_name, type: String

  # 10 character id
  field :hios_product_id, type: String
  field :hpid, type: String
  field :network_id, type: String
  field :service_area_id, type: String
  field :formulary_id, type: String

  # Plan attributes
  field :is_new_plan, type: String
  field :plan_type, type: String # hmo, ppo, pos, epo, indemnity
  field :metal_level, type: String
  field :unique_plan_design, type: String
  field :qhp_or_non_qhp, type: String # on_the_exchange, off_the_exchange, both
  field :insurance_plan_pregnancy_notice_req_ind, type: String
  field :is_specialist_referral_required, type: String
  field :health_care_specialist_referral_type, type: String, default: ""
  field :insurance_plan_benefit_exclusion_text, type: String
  field :ehb_percent_premium, type: String

  field :indian_plan_variation, type: String  # amount per enrollee

  # Required if small group
  field :hsa_eligibility, type: String
  field :employer_hsa_hra_contribution_indicator, type: String
  field :emp_contribution_amount_for_hsa_or_hra, type: Money # required if HSA Eligible

  field :child_only_offering, type: String  # allows_adult_and_child_only, allows_adult_only, allows_child_only
  field :child_only_plan_id, type: String
  field :is_wellness_program_offered, type: String
  field :is_disease_mgmt_programs_offered, type: String, default: ""

  ## Stand alone dental
  # Dollar amount
  field :ehb_apportionment_for_pediatric_dental, type: String
  field :guaranteed_vs_estimated_rate  # guaranteed_rate, estimated_rate

  ## AV Calculator Additional Benefit Design
  field :maximum_coinsurance_for_specialty_drugs, type: String

  # 1-10
  field :max_num_days_for_charging_inpatient_copay, type: String
  field :begin_primary_care_deductible_or_coinsurance_after_set_number_copays, type: String
  field :begin_primary_care_cost_sharing_after_set_number_visits, type: String

  ## Plan Dates
  field :plan_effective_date, type: Date
  field :plan_expiration_date, type: Date
  field :active_year, type: Integer

  ## Geographic Coverage
  field :out_of_country_coverage, type: String
  field :out_of_country_coverage_description, type: String
  field :out_of_service_area_coverage, type: String
  field :out_of_service_area_coverage_description, type: String
  field :national_network, type: String

  ## URLs
  field :summary_benefit_and_coverage_url, type: String
  field :enrollment_payment_url, type: String
  field :plan_brochure, type: String

  field :plan_id, type: BSON::ObjectId

  validates_presence_of :issuer_id, :state_postal_code, :standard_component_id, :plan_marketing_name, :hios_product_id,
                        :network_id, :service_area_id, :is_new_plan, :plan_type, :metal_level,
                        :qhp_or_non_qhp, :emp_contribution_amount_for_hsa_or_hra, :child_only_offering,
                        :plan_effective_date, :out_of_country_coverage, :out_of_service_area_coverage, :national_network

  scope :by_hios_ids_and_active_year, -> (sc_id, year) { where(:standard_component_id.in => sc_id, active_year: year ) }

  embeds_many :qhp_benefits,
    class_name: "Products::QhpBenefit",
    cascade_callbacks: true,
    validate: true

  embeds_many :qhp_cost_share_variances,
    class_name: "Products::QhpCostShareVariance",
    cascade_callbacks: true,
    validate: true

  accepts_nested_attributes_for :qhp_benefits, :qhp_cost_share_variances

  index({"issuer_id" => 1})
  index({"state_postal_code" => 1})
  index({"national_network" => 1})
  index({"tin" => 1}, {sparse: true})
  index({"qhp_benefits.benefit_type_code" => 1})
  index({"standard_component_id" => 1, "active_year" => 1})

  def plan=(new_plan)
    raise ArgumentError.new("expected Plan") unless new_plan.is_a? Plan
    self.plan_id = new_plan._id
    @plan = new_plan
  end

  def plan
    return @plan if defined? @plan
    @plan = Plan.find(plan_id) if plan_id.present?
  end

  VISIT_TYPES = [
    "Primary Care Visit to Treat an Injury or Illness",
    "Urgent Care Centers or Facilities",
    "Specialist Visit",
    "Emergency Room Services",
    "Inpatient Hospital Services (e.g., Hospital Stay)",
    "Laboratory Outpatient and Professional Services",
    "X-rays and Diagnostic Imaging",
    "Generic Drugs",
    "Preferred Brand Drugs",
    "Non-Preferred Brand Drugs",
    "Specialty Drugs"
  ]

  DENTAL_VISIT_TYPES = [
    "Routine Dental Services (Adult)",
    "Dental Check-Up for Children",
    "Basic Dental Care - Child",
    "Orthodontia - Child",
    "Major Dental Care - Child",
    "Basic Dental Care - Adult",
    "Orthodontia - Adult",
    "Major Dental Care - Adult",
    "Accidental Dental"
  ]


  def self.plan_hsa_status_map(plans)
    plan_hsa_status = {}
    @hios_ids = plans.map(&:hios_id)
    @year = plans.first.present? ? plans.first.active_year : ""
    qcsvs = get_cost_share_variances
    qcsvs.map {|qcsv| plan_hsa_status[qcsv.plan.id.to_s] = qcsv.qhp.hsa_eligibility}

    plan_hsa_status
  end

  def self.get_cost_share_variances
    Rails.cache.fetch("csvs-hios-ids-#{@hios_ids}-year-#{@year}", expires_in: 5.hour) do
      Products::QhpCostShareVariance.find_qhp_cost_share_variances(@hios_ids, @year, "")
    end
  end

  def self.csv_for(qhps, visit_types)
    (output = "").tap do
      CSV.generate(output) do |csv|
        csv_ary = []
        csv_ary << ["Carrier", "Plan Name", "Your Cost", "Provider NetWork", "Plan Benefits"] + visit_types
        qhps.each do |qhp|
          arry1 = [
            qhp.plan.carrier_profile.organization.legal_name,
            qhp.plan.name,
            "$#{qhp[:total_employee_cost].round(2)} / month",
            qhp.plan.nationwide ? "Nationwide" : qhp.plan.service_area_id,
            "Co-Pay"
          ]
          arry2 = [
            "","","","","Coinsurance"
          ]
          visit_types.each do |visit_type|
            service_visit = qhp.qhp_service_visits.detect{|a| a.visit_type == visit_type}
            if service_visit
              arry1 << (service_visit.present? ? service_visit.copay_in_network_tier_1 : "N/A")
              arry2 << (service_visit.present? ? service_visit.co_insurance_in_network_tier_1 : "N/A")
            else
              arry1 << "N/A"
              arry2 << "N/A"
            end
          end
          csv_ary << arry1
          csv_ary << arry2
        end

        inversion = convert_csv(csv_ary)
        inversion.each do |row|
          csv << row
        end
      end
    end
  end
end
