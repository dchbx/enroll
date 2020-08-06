# frozen_string_literal: true

class IvlNotices::FinalEligibilityNoticeAqhp < IvlNotice
  include ApplicationHelper
  attr_accessor :family, :data, :person, :renewing_enrollments, :active_enrollments

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store] = consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.person = args[:person]
    self.renewing_enrollments = args[:renewing_enrollments]
    self.active_enrollments = args[:active_enrollments]
    self.data = args[:data]
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_appeals
    attach_non_discrimination
    attach_taglines
    upload_and_send_secure_message

    send_generic_notice_alert if recipient.consumer_role.can_receive_electronic_communication?

    store_paper_notice if recipient.consumer_role.can_receive_paper_communication?
    clear_tmp(notice_path)
  end

  def build
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_identifier = recipient.hbx_id
    notice.coverage_year = TimeKeeper.date_of_record.next_year.year
    notice.current_year = TimeKeeper.date_of_record.year
    notice.ivl_open_enrollment_start_on = Settings.aca.individual_market.open_enrollment.start_on
    notice.ivl_open_enrollment_end_on = Settings.aca.individual_market.open_enrollment.end_on
    append_data
    append_hbe
    notice.primary_fullname = person.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end

  def append_data
    hbx_enrollments = []
    primary_member = data.detect{|m| m["subscriber"].upcase == "YES"}
    append_member_information_for_aqhp(primary_member)
    health_enrollments = renewing_enrollments.detect{ |e| e.coverage_kind == "health" && e.effective_on.year.to_s == notice.coverage_year}
    dental_enrollments = renewing_enrollments.detect{ |e| e.coverage_kind == "dental" && e.effective_on.year.to_s == notice.coverage_year}

    previous_health_enrollments = active_enrollments.detect{ |e| e.coverage_kind == "health" && e.effective_on.year.to_s == notice.current_year}
    previous_dental_enrollments = active_enrollments.detect{ |e| e.coverage_kind == "dental" && e.effective_on.year.to_s == notice.current_year}
    renewal_health_plan_id = begin
                               previous_health_enrollments.product.renewal_product_id
                             rescue StandardError
                               nil
                             end
    renewal_health_plan_hios_base_id = begin
                                         previous_health_enrollments.product.hios_base_id
                                       rescue StandardError
                                         nil
                                       end
    future_health_plan_id = begin
                              health_enrollments.product.id
                            rescue StandardError
                              nil
                            end
    future_health_plan_hios_base_id = begin
                                        health_enrollments.product.hios_base_id
                                      rescue StandardError
                                        nil
                                      end

    renewal_dental_plan_id = begin
                               previous_dental_enrollments.product.renewal_product_id
                             rescue StandardError
                               nil
                             end
    renewal_dental_plan_hios_base_id = begin
                                         previous_dental_enrollments.product.hios_base_id
                                       rescue StandardError
                                         nil
                                       end
    future_dental_plan_id = begin
                              dental_enrollments.product.id
                            rescue StandardError
                              nil
                            end
    future_dental_plan_hios_base_id = begin
                                        dental_enrollments.product.hios_base_id
                                      rescue StandardError
                                        nil
                                      end

    notice.same_plan_health_enrollment = renewal_health_plan_id && future_health_plan_id ? ((renewal_health_plan_id == future_health_plan_id) && (renewal_health_plan_hios_base_id == future_health_plan_hios_base_id)) : false
    notice.same_plan_dental_enrollment = renewal_dental_plan_id && future_dental_plan_id ? ((renewal_dental_plan_id == future_dental_plan_id) && (renewal_dental_plan_hios_base_id == future_dental_plan_hios_base_id)) : false

    hbx_enrollments << health_enrollments
    hbx_enrollments << dental_enrollments
    return nil if hbx_enrollments.flatten.compact.empty?
    notice.health_enrollments << (append_enrollment_information(health_enrollments) if health_enrollments)
    notice.dental_enrollments << (append_enrollment_information(dental_enrollments) if dental_enrollments)
    notice.health_enrollments.flatten!
    notice.health_enrollments.compact!
    notice.dental_enrollments.flatten!
    notice.dental_enrollments.compact!
    notice.enrollments << notice.health_enrollments
    notice.enrollments << notice.dental_enrollments
    notice.enrollments.flatten!
    notice.enrollments.compact!
    #append_enrollment_information
    notice.tax_households = append_tax_household_information(primary_member) if primary_member["aqhp_eligible"].upcase == "YES"
    notice.has_applied_for_assistance = check(primary_member["aqhp_eligible"])
    notice.primary_firstname = primary_member["first_name"].titleize
  end

  def append_member_information_for_aqhp(primary_member)
    data.collect do |datum|
      notice.individuals << PdfTemplates::Individual.new({
                                                           :first_name => datum["first_name"].titleize,
                                                           :last_name => datum["last_name"].titleize,
                                                           :full_name => datum["full_name"].titleize,
                                                           :age => calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')),
                                                           :incarcerated => datum["incarcerated"].present? && datum["incarcerated"].upcase == "N" ? "No" : "Yes",
                                                           :citizen_status => citizen_status(datum["citizen_status"]),
                                                           :residency_verified => datum["resident"].upcase == "YES" ? "Yes" : "No",
                                                           :actual_income => datum["actual_income"],
                                                           :taxhh_count => datum["tax_hh_count"],
                                                           :tax_status => filer_type(datum["filer_type"]),
                                                           :mec => datum["mec"].try(:upcase) == "YES" ? "Yes" : "No",
                                                           :is_ia_eligible => check(datum["aqhp_eligible"]),
                                                           :is_csr_eligible => datum["csr"].try(:upcase) == "YES",
                                                           :indian_conflict => check(datum["indian"]),
                                                           :is_medicaid_chip_eligible => check(datum["magi_medicaid"]),
                                                           :is_non_magi_medicaid_eligible => check(datum["non_magi_medicaid"]),
                                                           :is_without_assistance => check(datum["uqhp_eligible"]),
                                                           :is_totally_ineligible => check(datum["totally_inelig"]),
                                                           :magi_medicaid_monthly_income_limit => datum["medicaid_monthly_income_limit"],
                                                           :magi_as_percentage_of_fpl => datum["magi_as_fpl"],
                                                           :has_access_to_affordable_coverage => check(datum ["mec"]),
                                                           :no_medicaid_because_of_income => datum["nonmedi_reason"].present? && datum["nonmedi_reason"].downcase == "over income" ? true : false,
                                                           :no_medicaid_because_of_immigration => datum["nonmedi_reason"].present? && datum["nonmedi_reason"].downcase == "immigration" ? true : false,
                                                           :no_medicaid_because_of_age => datum["nonmedi_reason"].present? && datum["nonmedi_reason"].downcase == "age" ? true : false,
                                                           :no_aptc_because_of_income => datum["nonaptc_reason"].present? && datum["nonaptc_reason"].downcase == "over income" ? true : false,
                                                           :no_aptc_because_of_tax => datum["nonaptc_reason"].present? && datum["nonaptc_reason"].downcase == "tax" ? true : false,
                                                           :no_aptc_because_of_mec => datum["nonaptc_reason"].present? && datum["nonaptc_reason"].downcase == "medicare eligible" ? true : false,
                                                           :no_csr_because_of_income => datum["noncsr_reason"].present? && datum["noncsr_reason"].downcase == "over income" ? true : false,
                                                           :no_csr_because_of_tax => datum["noncsr_reason"].present? && datum["noncsr_reason"].downcase == "tax" ? true : false,
                                                           :no_csr_because_of_mec => datum["noncsr_reason"].present? && datum["noncsr_reason"].downcase == "medicare eligible" ? true : false,
                                                           :non_applicant => datum["nonaptc_reason"].present? && datum["nonaptc_reason"].downcase == "non-applicant" ? true : false,
                                                           :tax_household => append_tax_household_information(primary_member)
                                                         })
    end
  end

  def append_enrollment_information(enrollment)
    plan = PdfTemplates::Plan.new({
                                    plan_name: enrollment.product.title,
                                    is_csr: enrollment.product.is_csr?,
                                    coverage_kind: enrollment.product.kind,
                                    plan_carrier: enrollment.product.issuer_profile.organization.legal_name,
                                    family_deductible: enrollment.product.family_deductible.split("|").last.squish,
                                    deductible: enrollment.product.deductible
                                  })
    PdfTemplates::Enrollment.new({
                                   premium: enrollment.total_premium.round(2),
                                   aptc_amount: enrollment.applied_aptc_amount.round(2),
                                   responsible_amount: number_to_currency((enrollment.total_premium - enrollment.applied_aptc_amount.to_f), precision: 2),
                                   phone: phone_number(enrollment.product.issuer_profile.legal_name),
                                   is_receiving_assistance: enrollment.applied_aptc_amount > 0 || enrollment.product.is_csr? ? true : false,
                                   coverage_kind: enrollment.coverage_kind,
                                   kind: enrollment.kind,
                                   effective_on: enrollment.effective_on,
                                   plan: plan,
                                   enrollees: enrollment.hbx_enrollment_members.inject([]) do |enrollees, member|
                                                enrollee = PdfTemplates::Individual.new({
                                                                                          full_name: member.person.full_name.titleize,
                                                                                          age: member.person.age_on(TimeKeeper.date_of_record)
                                                                                        })
                                                enrollees << enrollee
                                              end
                                 })
  end

  def phone_number(legal_name)
    case legal_name
    when "BestLife"
      "(800) 433-0088"
    when "CareFirst"
      "(855) 444-3119"
    when "Delta Dental"
      "(800) 471-0236"
    when "Dominion"
      "(855) 224-3016"
    when "Kaiser"
      "(844) 524-7370"
    end
  end

  def append_tax_household_information(primary_member)
    PdfTemplates::TaxHousehold.new({
                                     :csr_percent_as_integer => primary_member["csr"].present? && primary_member["csr"].upcase == "YES" ? primary_member["csr_percent"] : "100",
                                     :max_aptc => primary_member["aptc"].present? ? primary_member["aptc"].to_f.round(2) : 0.0,
                                     :aptc_csr_annual_household_income => primary_member["actual_income"].present? ? primary_member["actual_income"].to_f.round(2) : nil,
                                     :aptc_csr_monthly_household_income => primary_member["monthly_hh_income"].present? ? primary_member["monthly_hh_income"].to_f.round(2) : nil,
                                     :aptc_annual_income_limit => primary_member["aptc_annual_limit"].present? ? primary_member["aptc_annual_limit"].to_f.round(2) : nil,
                                     :csr_annual_income_limit => primary_member["csr_annual_income_limit"].present? ? primary_member["csr_annual_income_limit"].to_f.round(2) : nil,
                                     :applied_aptc => primary_member["applied_aptc"].presence || 0.0
                                   })
  end

  def filer_type(type)
    case type
    when "Filers"
      "Tax Filer"
    when "Dependents"
      "Tax Dependent"
    when "Married Filing Jointly"
      "Married Filing Jointly"
    else
      ""
    end
  end

  def citizen_status(status)
    case status
    when "US"
      "US Citizen"
    when "LP"
      "Lawfully Present"
    when "NC"
      "US Citizen"
    else
      ""
    end
  end

end
