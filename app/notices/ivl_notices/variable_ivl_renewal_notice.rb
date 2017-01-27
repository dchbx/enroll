class IvlNotices::VariableIvlRenewalNotice < IvlNotice
  attr_accessor :family, :data,:identifier, :person,:address, :enrollment_group_ids, :plan_data_2016

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.data = args[:data]
    self.enrollment_group_ids = args[:enrollment_group_ids]
    self.plan_data_2016 = args[:plan_data_2016]
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end

  def build
    family = recipient.primary_family
    enrollments_2017 = family.all_enrollments.where(:hbx_id => {"$in" => enrollment_group_ids})
    enrollments_2016 = []
    corresponding_2016_plans = []
    enrollments_2017.each do |enrollment|
      hios_id_2016 = plan_data_2016[enrollment.hbx_id]
      enrollments_2016 << build_2016_enrollment_from_csv_data(hios_id_2016,enrollment)
    end
    hbx_enrollments = enrollments_2017 + enrollments_2016
    append_enrollments(hbx_enrollments)
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else  
      # @notice.primary_address = nil
      raise 'mailing address not present' 
    end
  end

  def append_enrollments(hbx_enrollments)
    enrollments_for_notice = []
    enrollments_for_notice << health_enrollment(hbx_enrollments)
    enrollments_for_notice << dental_enrollment(hbx_enrollments)
    enrollments_for_notice << renewal_health_enrollment(hbx_enrollments)
    enrollments_for_notice << renewal_dental_enrollment(hbx_enrollments)
    enrollments_for_notice.compact!
    enrollments_for_notice.each do |hbx_enrollment|
      @notice.enrollments << build_enrollment(hbx_enrollment)
    end
  end

  def build_2016_enrollment_from_csv_data(plan_hios_id,enrollment_2017)
    hbx_enrollment = OpenStruct.new
    plan = Plan.where(:hios_id => plan_hios_id, :active_year => 2016).first
    hbx_enrollment.plan = plan
    hbx_enrollment.total_premium = 0.00.to_d
    hbx_enrollment.applied_aptc_amount = 0.00.to_d
    hbx_enrollment.responsible_amount = 0.00.to_d
    hbx_enrollment.phone = enrollment_2017.phone_number
    hbx_enrollment.effective_on = Date.new(2016,1,1)
    hbx_enrollment.selected_on = DateTime.new(2016,1,1,0,0,0)
    hbx_enrollment.coverage_kind = plan.coverage_kind
    hbx_enrollment.hbx_enrollment_members = enrollment_2017.hbx_enrollment_members
    return hbx_enrollment
  end

  def build_enrollment(hbx_enrollment)
    plan_template = PdfTemplates::Plan.new({
      plan_name: hbx_enrollment.plan.name,
      metal_level: hbx_enrollment.plan.metal_level,
      coverage_kind: hbx_enrollment.plan.coverage_kind,
      plan_carrier: hbx_enrollment.plan.carrier_profile.organization.legal_name,
      hsa_plan: hbx_enrollment.plan.hsa_plan?,
      renewal_plan_type: hbx_enrollment.plan.renewal_plan_type
      })
    PdfTemplates::Enrollment.new({
      premium: hbx_enrollment.total_premium.round(2),
      aptc_amount: hbx_enrollment.applied_aptc_amount.round(2),
      responsible_amount: (hbx_enrollment.total_premium - hbx_enrollment.applied_aptc_amount.to_f).round(2),
      phone: hbx_enrollment.phone_number,
      effective_on: hbx_enrollment.effective_on,
      selected_on: hbx_enrollment.created_at,
      plan: plan_template,
      enrollees: hbx_enrollment.hbx_enrollment_members.inject([]) do |names, member|
        names << member.person.full_name.titleize
        end
    })
  end

  def health_enrollment(hbx_enrollments)
    return hbx_enrollments.select{|hbx_enrollment| hbx_enrollment.coverage_kind == "health" && hbx_enrollment.effective_on < Date.new(2017,1,1)}.sort_by{|hbx_enrollment| hbx_enrollment.effective_on}.last
  end

  def dental_enrollment(hbx_enrollments)
    return hbx_enrollments.select{|hbx_enrollment| hbx_enrollment.coverage_kind == "dental" && hbx_enrollment.effective_on < Date.new(2017,1,1)}.sort_by{|hbx_enrollment| hbx_enrollment.effective_on}.last
  end

  def renewal_health_enrollment(hbx_enrollments)
    return hbx_enrollments.select{|hbx_enrollment| hbx_enrollment.coverage_kind == "health" && hbx_enrollment.effective_on >= Date.new(2017,1,1)}.sort_by{|hbx_enrollment| hbx_enrollment.effective_on}.last
  end

  def renewal_dental_enrollment(hbx_enrollments)
    return hbx_enrollments.select{|hbx_enrollment| hbx_enrollment.coverage_kind == "dental" && hbx_enrollment.effective_on >= Date.new(2017,1,1)}.sort_by{|hbx_enrollment| hbx_enrollment.effective_on}.last    
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: capitalize_quadrant(primary_address.address_1.to_s.titleize),
      street_2: capitalize_quadrant(primary_address.address_2.to_s.titleize),
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def capitalize_quadrant(address_line)
    address_line.split(/\s/).map do |x| 
      x.strip.match(/^NW$|^NE$|^SE$|^SW$/i).present? ? x.strip.upcase : x.strip
    end.join(' ')
  end

end