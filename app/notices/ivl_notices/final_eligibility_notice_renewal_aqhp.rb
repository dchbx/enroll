# frozen_string_literal: true

class IvlNotices::FinalEligibilityNoticeRenewalAqhp < IvlNotice
  include ApplicationHelper
  attr_accessor :family, :data, :person, :enrollments, :renewing_enrollments, :active_enrollments

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store] = consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.person = args[:person]
    self.renewing_enrollments = args[:renewing_enrollments]
    self.active_enrollments = args[:active_enrollments]
    self.enrollments = args[:renewing_enrollments] + args[:active_enrollments]
    self.data = args[:data]
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_required_documents if notice.documents_needed
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
    check_for_unverified_individuals
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
    primary_member = data.detect{|m| m["subscriber"].upcase == "YES"}
    append_member_information_for_aqhp(primary_member)
    append_enrollment_information
    notice.tax_households = append_tax_household_information(primary_member) if primary_member["aqhp_eligible"].upcase == "YES"
    notice.has_applied_for_assistance = check(primary_member["aqhp_eligible"])
    notice.primary_firstname = primary_member["first_name"]
    notice.due_date = TimeKeeper.date_of_record + 95.days
    notice.documents_needed = data.any?{|d| d["docs_needed"].try(:upcase) == 'Y'}
    append_document_information
  end

  def append_member_information_for_aqhp(primary_member)
    data.collect do |datum|
      notice.individuals << PdfTemplates::Individual.new({
                                                           :first_name => datum["first_name"].titleize,
                                                           :last_name => datum["last_name"].titleize,
                                                           :full_name => datum["full_name"].titleize,
                                                           :age => calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')),
                                                           :incarcerated => datum["incarcerated"].upcase == "N" ? "No" : "Yes",
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
                                                           :is_without_assistance => check(datum["uqhp_eligible"]),
                                                           :tax_household => append_tax_household_information(primary_member)
                                                         })
    end
  end

  def append_document_information
    data.collect do |datum|
      ssn_doc_needed = datum["ssn_doc_needed"].try(:upcase) == "Y"
      citizenship_doc_needed = datum["citizenship_doc_needed"].try(:upcase) == "Y"
      immigration_doc_needed = datum["immigration_doc_needed"].try(:upcase) == "Y"
      income_doc_needed = datum["income_doc_needed"].try(:upcase) == "Y"
      other_coverage_doc_needed = datum["other_coverage_doc_needed"].try(:upcase) == "Y"
      notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: datum["full_name"].titleize, documents_due_date: notice.due_date, age: calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')) }) if ssn_doc_needed

      notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: datum["full_name"].titleize, documents_due_date: notice.due_date, age: calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')) }) if citizenship_doc_needed

      notice.immigration_unverified << PdfTemplates::Individual.new({ full_name: datum["full_name"].titleize, documents_due_date: notice.due_date, age: calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')) }) if immigration_doc_needed

      notice.income_unverified << PdfTemplates::Individual.new({ full_name: datum["full_name"].titleize, documents_due_date: notice.due_date, age: calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')) }) if income_doc_needed

      if other_coverage_doc_needed
        notice.mec_conflict << PdfTemplates::Individual.new({ full_name: datum["full_name"].titleize, documents_due_date: notice.due_date, age: calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')), mec_type_1: datum["mec_type_1"], mec_type_2: datum["mec_type_2"] })
      end
    end
  end

  def append_enrollment_information
    renewing_enrollments.each do |enrollment|
      plan = PdfTemplates::Plan.new({
                                      plan_name: enrollment.product.title,
                                      is_csr: enrollment.product.is_csr?,
                                      coverage_kind: enrollment.product.kind,
                                      plan_carrier: enrollment.product.issuer_profile.organization.legal_name,
                                      family_deductible: enrollment.product.family_deductible.split("|").last.squish,
                                      deductible: enrollment.product.deductible
                                    })
      notice.enrollments << PdfTemplates::Enrollment.new({
                                                           premium: enrollment.total_premium.round(2),
                                                           aptc_amount: enrollment.applied_aptc_amount.round(2),
                                                           responsible_amount: (enrollment.total_premium - enrollment.applied_aptc_amount.to_f).round(2),
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
  end

  def check_for_unverified_individuals
    family = recipient.primary_family
    enrollments = enrollments_for_family(family).select do |hbx_en|
      !hbx_en.is_shop? && !["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state) &&
        (
        hbx_en.terminated_on.blank? ||
            hbx_en.terminated_on >= TimeKeeper.date_of_record
      )
    end
    enrollments.reject!(&:coverage_terminated?)
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq

    people = family_members.map(&:person).uniq
  end

  def document_due_date(family)
    enrolled_contingent_enrollment = enrollments_for_family(family).outstanding_enrollments.first
    if enrolled_contingent_enrollment.present?
      if enrolled_contingent_enrollment.special_verification_period.present?
        enrolled_contingent_enrollment.special_verification_period
      else
        (TimeKeeper.date_of_record + 95.days)
      end
    end
  end

  def enrollments_for_family(family)
    @enrollments_for_family ||= HbxEnrollment.where(family_id: family.id)
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
                                     :csr_percent_as_integer => primary_member["csr"].upcase == "YES" ? primary_member["csr_percent"] : "100",
                                     :max_aptc => primary_member["aptc"].present? ? primary_member["aptc"].to_f.round(2) : 0.0,
                                     :aptc_csr_annual_household_income => primary_member["actual_income"].present? ? primary_member["actual_income"].to_f.round(2) : nil,
                                     :aptc_csr_monthly_household_income => primary_member["monthly_hh_income"].present? ? primary_member["monthly_hh_income"].to_f.round(2) : nil,
                                     :aptc_annual_income_limit => primary_member["aptc_annual_limit"].present? ? primary_member["aptc_annual_limit"].to_f.round(2) : nil,
                                     :csr_annual_income_limit => primary_member["csr_annual_income_limit"].present? ? primary_member["csr_annual_income_limit"].to_f.round(2) : nil,
                                     :applied_aptc => primary_member["applied_aptc"].present? ? primary_member["applied_aptc"] : 0.0
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