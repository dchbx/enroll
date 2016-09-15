class IvlNotices::ConsumerNotice < IvlNotice
  attr_accessor :family

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person.primary_family
    args[:to] = consumer_role.person.work_email_or_best
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end

  def build
    family = recipient.primary_family    
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else  
      # @notice.primary_address = nil
      raise 'mailing address not present' 
    end

    append_unverified_family_members
  end

  def append_unverified_family_members
    enrollments = recipient.primary_family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
      (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
        (
          hbx_en.terminated_on.blank? ||
          hbx_en.terminated_on >= TimeKeeper.date_of_record
        )
    end

    enrollments.reject!{|e| e.coverage_terminated? }
    enrollments.reject!{|e| e.effective_on.year != TimeKeeper.date_of_record.year }

    if enrollments.empty?
      raise 'enrollments not found!'
    end
  
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq

    people = family_members.map(&:person).uniq
    people.reject!{|p| p.consumer_role.aasm_state != 'verification_outstanding'}
    people.reject!{|person| !ssn_outstanding?(person) && !lawful_presence_outstanding?(person) }
    if people.empty?
      raise 'no family member found with outstanding verification'
    end

    outstanding_people = []
    people.each do |person|
      if person.consumer_role.outstanding_verification_types.present?
        outstanding_people << person
      end
    end

    outstanding_people.uniq!
    if outstanding_people.empty?
      raise 'no family member found without uploaded documents'
    end

    # enrollments.each {|e| e.update_attributes(special_verification_period: TimeKeeper.date_of_record + 95.days)}

    append_unverified_individuals(outstanding_people)
    notice.enrollments << (enrollments.detect{|e| e.enrolled_contingent?} || enrollments.first)
    notice.due_date = enrollments.first.special_verification_period.strftime("%m/%d/%Y")
  end

  def ssn_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?("Social Security Number")
  end

  def lawful_presence_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('Citizenship') || person.consumer_role.outstanding_verification_types.include?('Immigration status')
  end

  def append_unverified_individuals(people)
    people.each do |person|
      if ssn_outstanding?(person)
        notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize })
      end

      if lawful_presence_outstanding?(person)
        notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize })
      end
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

  def to_csv
    [
      recipient.hbx_id,
      recipient.first_name,
      recipient.last_name,
      notice.primary_address.present? ? notice.primary_address.attributes.values.reject{|x| x.blank?}.compact.join(',') : "",
      notice.due_date,
      (notice.enrollments.first.submitted_at || notice.enrollments.first.created_at),
      notice.enrollments.first.effective_on,
      notice.ssa_unverified.map{|individual| individual.full_name }.join(','),
      notice.dhs_unverified.map{|individual| individual.full_name }.join(','),
      recipient.consumer_role.contact_method,
      recipient.home_email.try(:address) || recipient.user.try(:email),
      notice.enrollments.first.aasm_state.to_s
    ]
  end
end 