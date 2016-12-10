module ConsumerRolesHelper
  def ethnicity_collection
    [
      ["White", "Black or African American", "Asian Indian", "Chinese" ],
      ["Filipino", "Japanese", "Korean", "Vietnamese", "Other Asian"],
      ["Native Hawaiian", "Samoan", "Guamanian or Chamorro", ],
      ["Other Pacific Islander", "American Indian or Alaskan Native", "Other"]

    ].inject([]){ |sets, ethnicities|
      sets << ethnicities.map{|e| OpenStruct.new({name: e, value: e})}
    }
  end

  def latino_collection
    [
      ["Mexican", "Mexican American"],
      ["Chicano/a", "Puerto Rican"],
      ["Cuban", "Other"]
    ].inject([]){ |sets, ethnicities|
      sets << ethnicities.map{|e| OpenStruct.new({name: e, value: e})}
    }
  end

  def find_consumer_role_for_fields(obj)
    if obj.is_a? Person
      obj.consumer_role
    elsif obj.persisted?
      obj.family_member.person.consumer_role
    else
      ConsumerRole.new
    end
  end

  def show_naturalized_citizen_container(obj)
    obj.try(:us_citizen)
  end

  def show_immigration_status_container(obj)
    obj.try(:us_citizen) == false
  end

  def show_tribal_container(obj)
    obj.try(:indian_tribe_member)
  end

  def show_naturalization_doc_type(obj)
    show_naturalized_citizen_container(obj) and obj.try(:naturalized_citizen)
  end

  def show_immigration_doc_type(obj)
    show_immigration_status_container(obj) and obj.try(:eligible_immigration_status)
  end

  def show_vlp_documents_container(obj)
    show_naturalization_doc_type(obj) || show_immigration_doc_type(obj)
  end

  # just work for ivl
  def show_keep_existing_plan(shop_for_plans, hbx_enrollment, new_effective_on)
    return true if hbx_enrollment.is_shop?

    shop_for_plans.blank? && (hbx_enrollment.effective_on.year == (new_effective_on.present? ? new_effective_on.year : nil))
  end

  def show_consumer_role_state(consumer_role)
    return "" if consumer_role.blank?
    if consumer_role.unverified? || consumer_role.ssa_pending? || consumer_role.dhs_pending?
      "Pending"
    elsif consumer_role.fully_verified?
      "Verified"
    else
      "Outstanding verification"
    end
  end

  def required_for_consumer_address(required, has_dc_adress)
    required.present? && has_dc_adress
  end
end
