module VerificationHelper

  def doc_status_label(doc)
    case doc.status
      when "not submitted"
        "warning"
      when "downloaded"
        "default"
      when "verified"
        "success"
      else
        "danger"
    end
  end

  def verification_type_status(type, member, admin=false)
    consumer = member.consumer_role
    return "curam" if (consumer.vlp_authority == "curam" && consumer.fully_verified? && admin)
    case type
      when 'Social Security Number'
        if consumer.ssn_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.ssn_rejected
          "in review"
        else
          "outstanding"
        end
      when 'American Indian Status'
        if consumer.native_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.native_rejected
          "in review"
        else
          "outstanding"
        end
      else
        if consumer.lawful_presence_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.lawful_presence_rejected
          "in review"
        else
          "outstanding"
        end
    end
  end

  def ridp_type_status(type, person)
    consumer = person.consumer_role
    case type
      when 'Identity'
        if consumer.identity_verified?
          consumer.identity_validation
        elsif consumer.has_ridp_docs_for_type?(type) && !consumer.identity_rejected
          'in review'
        else
          'outstanding'
        end
      when 'Application'
        if consumer.application_verified?
          consumer.application_validation
        elsif consumer.has_ridp_docs_for_type?(type) && !consumer.application_rejected
          'in review'
        else
          'outstanding'
        end
    end
  end

  def verification_type_class(type, member, admin=false)
    case verification_type_status(type, member, admin)
      when "verified"
        "success"
      when "in review"
        "warning"
      when "outstanding"
        member.consumer_role.processing_hub_24h? ? "info" : "danger"
      when "curam"
        "default"
    end
  end

  def ridp_type_class(type, person)
    case ridp_type_status(type, person)
      when 'valid'
        'success'
      when 'in review'
        'warning'
      when 'outstanding'
        'danger'
    end
  end

  def unverified?(person)
    person.consumer_role.aasm_state != "fully_verified"
  end

  def enrollment_group_unverified?(person)
    person.primary_family.contingent_enrolled_active_family_members.any? {|member| member.person.consumer_role.aasm_state == "verification_outstanding"}
  end

  def verification_needed?(person)
    person.primary_family.active_household.hbx_enrollments.verification_needed.any? if person.try(:primary_family).try(:active_household).try(:hbx_enrollments)
  end

  def has_enrolled_policy?(family_member)
    return true if family_member.blank?
    family_member.family.enrolled_policy(family_member).present?
  end

  def is_not_verified?(family_member, v_type)
    return true if family_member.blank?
    !family_member.person.consumer_role.is_type_verified?(v_type)
  end

  def can_show_due_date?(person, options ={})
    enrollment_group_unverified?(person) && verification_needed?(person) && (has_enrolled_policy?(options[:f_member]) && is_not_verified?(options[:f_member], options[:v_type]))
  end

  def documents_uploaded
    @person.primary_family.active_family_members.all? { |member| docs_uploaded_for_all_types(member) }
  end

  def member_has_uploaded_docs(member)
    true if member.person.consumer_role.try(:vlp_documents).any? { |doc| doc.identifier }
  end

  def member_has_uploaded_paper_applications(member)
    true if member.person.resident_role.try(:paper_applications).any? { |doc| doc.identifier }
  end

  def docs_uploaded_for_all_types(member)
    member.person.verification_types.all? do |type|
      member.person.consumer_role.vlp_documents.any?{ |doc| doc.identifier && doc.verification_type == type }
    end
  end

  def documents_count(family)
    family.family_members.map(&:person).flat_map(&:consumer_role).flat_map(&:vlp_documents).select{|doc| doc.identifier}.count
  end

  def review_button_class(family)
    if family.active_household.hbx_enrollments.verification_needed.any?
      people = family.family_members.map(&:person)
      v_types_list = get_person_v_type_status(people)
      if !v_types_list.include?('outstanding')
        'success'
      elsif v_types_list.include?('in review') && v_types_list.include?('outstanding')
        'info'
      else
        'default'
      end
    end
  end

  def get_person_v_type_status(people)
    v_type_status_list = []
    people.each do |person|
      person.verification_types.each do |v_type|
        v_type_status_list << verification_type_status(v_type, person)
      end
    end
    v_type_status_list
  end

  def show_send_button_for_consumer?
    current_user.has_consumer_role? && hbx_enrollment_incomplete && documents_uploaded
  end

  def hbx_enrollment_incomplete
    if @person.primary_family.active_household.hbx_enrollments.verification_needed.any?
      @person.primary_family.active_household.hbx_enrollments.verification_needed.first.review_status == "incomplete"
    end
  end

  #use this method to send docs to review for family member level
  def all_docs_rejected(person)
    person.try(:consumer_role).try(:vlp_documents).select{|doc| doc.identifier}.all?{|doc| doc.status == "rejected"}
  end

  def no_enrollments
    @person.primary_family.active_household.hbx_enrollments.empty?
  end

  def enrollment_incomplete
    if @person.primary_family.active_household.hbx_enrollments.verification_needed.any?
      @person.primary_family.active_household.hbx_enrollments.verification_needed.first.review_status == "incomplete"
    end
  end

  def all_family_members_verified
    @family_members.all?{|member| member.person.consumer_role.aasm_state == "fully_verified"}
  end

  def show_doc_status(status)
    ["verified", "rejected"].include?(status)
  end

  def show_v_type(v_type, person, admin = false)
    case verification_type_status(v_type, person, admin)
      when "in review"
        "&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;".html_safe
      when "verified"
        "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".html_safe
      when "curam"
        admin ? "External source" : "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".html_safe
      else
        person.consumer_role.processing_hub_24h? ? "&nbsp;&nbsp;Processing&nbsp;&nbsp;".html_safe : "Outstanding"
    end
  end

  def show_ridp_type(ridp_type, person)
    case ridp_type_status(ridp_type, person)
      when 'in review'
        "&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;".html_safe
      when 'valid'
        "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".html_safe
      else
        "&nbsp;&nbsp;Outstanding&nbsp;&nbsp;".html_safe
    end
  end

  def text_center(v_type, person)
    (current_user && !current_user.has_hbx_staff_role?) || show_v_type(v_type, person) == '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
  end

  # returns vlp_documents array for verification type
  def documents_list(person, v_type)
    person.consumer_role.vlp_documents.select{|doc| doc.identifier && doc.verification_type == v_type } if person.consumer_role
  end

  # returns ridp_documents array for verification type
  def ridp_documents_list(person, ridp_type)
    person.consumer_role.ridp_documents.select{|doc| doc.identifier && doc.ridp_verification_type == ridp_type } if person.consumer_role
  end

  def admin_actions(v_type, f_member)
    options_for_select(build_admin_actions_list(v_type, f_member))
  end

  def ridp_admin_actions(ridp_type, person)
    options_for_select(build_ridp_admin_actions_list(ridp_type, person))
  end

  def build_admin_actions_list(v_type, f_member)
    if verification_type_status(v_type, f_member) == "outstanding"
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS.reject{|el| el == "Reject"}
    else
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS
    end
  end

  def build_ridp_admin_actions_list(ridp_type, person)
    if ridp_type_status(ridp_type, person) == 'outstanding'
      ::RidpDocument::ADMIN_VERIFICATION_ACTIONS.reject{|el| el == 'Reject'}
    else
      ::RidpDocument::ADMIN_VERIFICATION_ACTIONS
    end
  end

  def type_unverified?(v_type, person)
    verification_type_status(v_type, person) != "verified"
  end

  def ridp_type_unverified?(ridp_type, person)
    ridp_type_status(ridp_type, person) != 'valid'
  end
end
