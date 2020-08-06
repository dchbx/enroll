# frozen_string_literal: true

class IvlNotices::NoticeBuilder

  attr_reader :notice, :consumer, :subject, :template, :builder_template

  def initialize(builder_template, options = {})
    @template = options[:template]
    @subject = options[:subject]
    @builder_template = builder_template
  end

  def build
    @notice = @builder_template.new
    @notice.primary_fullname = @consumer.full_name.titleize
    @notice.primary_identifier = @consumer.hbx_id
    @notice.first_name = @consumer.first_name.titleize
    @notice.last_name = @consumer.last_name.titleize
    append_mailing_address(@consumer.mailing_address)
  end

  def append_mailing_address(mailing_address)
    @notice.primary_address = PdfTemplates::NoticeAddress.new({
                                                                street_1: mailing_address.address_1.titleize,
                                                                street_2: mailing_address.address_2.titleize,
                                                                city: mailing_address.city.titleize,
                                                                state: mailing_address.state,
                                                                zip: mailing_address.zip
                                                              })
  end

  def append_enrollments(hbx_enrollments)
    # @notice.enrollments << build_enrollment(@hbx_enrollment)
    # other_enrollments = hbx_enrollments.reject{|hbx_enrollment| hbx_enrollment.id.to_s == @hbx_enrollment_id}
    # other_enrollments.each do |hbx_enrollment|
    #   @notice.enrollments << build_enrollment(hbx_enrollment)
    # end

    hbx_enrollments.each do |hbx_enrollment|
      @notice.enrollments << build_enrollment(hbx_enrollment)
    end
  end

  def append_individuals(hbx_enrollments)
    enrolled_members = []
    hbx_enrollments.each do |hbx_enrollment|
      enrolled_members += hbx_enrollment.hbx_enrollment_members.map(&:person)
    end
    enrolled_members.uniq.each do |person|
      @notice.individuals << build_individual(person)
    end
  end

  def build_individual(person)
    params = { full_name: person.full_name }
    if consumer_role = person.consumer_role
      params.merge!({
                      ssn_verified: consumer_role.ssn_verified?,
                      citizenship_verified: consumer_role.citizenship_verified?,
                      residency_verified: !consumer_role.residency_denied?,
                      indian_conflict: consumer_role.indian_conflict?,
                      incarcerated: consumer_role.is_incarcerated?
                    })
    end
    PdfTemplates::Individual.new(params)
  end

  def build_enrollment(hbx_enrollment)
    PdfTemplates::Enrollment.new({
                                   plan_name: hbx_enrollment.plan.name,
                                   premium: hbx_enrollment.total_premium,
                                   phone: hbx_enrollment.phone_number,
                                   effective_on: hbx_enrollment.effective_on,
                                   selected_on: hbx_enrollment.created_at,
                                   enrollees: hbx_enrollment.hbx_enrollment_members.inject([]) do |names, member|
                                                names << member.person.full_name.titleize
                                              end
                                 })
  end

  def generate_pdf_notice
    ivl_notice = IvlNotice.new
    ivl_notice.notice = @notice
    ivl_notice.template = @template
    ivl_notice.create
    ivl_notice.upload
  end

  def generate_html
    ivl_notice = IvlNotice.new
    ivl_notice.notice = @notice
    ivl_notice.template = @template
    ivl_notice.save_html
  end
end