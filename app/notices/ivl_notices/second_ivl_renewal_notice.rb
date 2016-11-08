class IvlNotices::SecondIvlRenewalNotice < IvlNotice
  attr_accessor :family, :data,:identifier, :person,:address

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person.families.first.primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person.families.first.primary_applicant.person
    args[:to] = consumer_role.person.families.first.primary_applicant.person.work_email_or_best
    self.person = args[:person]
    self.address = Address.new(args[:address])
    self.data = args[:data]
    self.identifier = args[:primary_identifier]
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
    notice.primary_identifier = "Account ID: #{identifier}"
    notice.primary_fullname = person.full_name.titleize || ""
    if address
      append_address(address)
    else  
      # @notice.primary_address = nil
      raise 'mailing address not present' 
    end
  end

  def append_data
    notice.individuals=data.collect do |datum|
        
        # person = Person.where(:hbx_id => datum["hbx_id"]).first
        PdfTemplates::Individual.new({
          :full_name => datum["full_name"],
          :incarcerated=>datum["incarcerated"].try(:upcase) == "N" ? "No" : "",
          :citizen_status=> citizen_status(datum["citizen_status"]),
          :residency_verified => datum["resident"].try(:upcase) == "Y"  ? "District of Columbia Resident" : "Not a District of Columbia Resident",
          :projected_amount => datum["actual_income"],
          :taxhh_count => datum["taxhhcount"],
          :uqhp_reason => datum["uqhp_reason"],
          :tax_status => filer_type(datum["filer_type"]),
          :mec => datum["mec"].upcase == "N" ? "None" : "Yes"

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

  def filer_type(type)
    case type
    when "Filers"
      "Tax Filer"
    when "Dependents"
      "Tax Dependent"
    when "None"
      "Does not file taxes"
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
    when "NLP"
      "Not Lawfully Present"
    else
      ""
    end
  end

end