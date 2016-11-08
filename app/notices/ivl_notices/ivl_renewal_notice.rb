class IvlNotices::IvlRenewalNotice < IvlNotice
  attr_accessor :family, :data

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.data = args[:data]
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page
    attach_voter_application
    prepend_envelope
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def attach_voter_application
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'voter_application.pdf')]
  end

  def build
    family = recipient.primary_family
    append_data
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else  
      # @notice.primary_address = nil
      raise 'mailing address not present' 
    end
  end

  def append_data
    notice.individuals=data.collect do |datum|
        person = Person.where(:hbx_id => datum["glue_hbx_id"]).first
        PdfTemplates::Individual.new({
          :full_name => person.full_name,
          :incarcerated=> datum["ea_incarcerated"].try(:upcase) == "FALSE" ? "No" : "Yes",
          :citizen_status=> citizen_status(datum["ea_citizenship"]),
          :residency_verified => datum["ea_dc_resident"].try(:upcase) == "TRUE"  ? "District of Columbia Resident" : "Not a District of Columbia Resident"
        })
    end
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

  def citizen_status(status)
    case status
    when "us_citizen"
      "U.S. Citizen"
    when "alien_lawfully_present"
      "Lawfully Present"
    when "indian_tribe_member"
      "U.S. Citizen"
    when "naturalized_citizen"
      "U.S. Citizen"
    else
      "Not Lawfully Present"
    end
  end

end