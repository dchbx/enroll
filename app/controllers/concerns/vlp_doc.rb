module VlpDoc
  include ErrorBubble
  def vlp_doc_params_list
    [
      {:consumer_role =>
       [:vlp_documents_attributes =>
        [:subject, :citizenship_number, :naturalization_number,
         :alien_number, :passport_number, :sevis_id, :visa_number,
         :receipt_number, :expiration_date, :card_number, :description,
         :i94_number, :country_of_citizenship]]}
    ]
  end

  def run_validate_vlp_params?(params, source, consumer_role)
    if consumer_role.present?
      # This means that they are completely verified and require no validation
      return false if consumer_role.local_residency_validation == 'attested' && consumer_role.residency_determined_at.present?
    end
    # REFS 88247: This will prevent an error from being thrown that
    # doesn't allow updating of person that has VLP docs, but has verified residency status
    # This commit originally fixed the bug in 88247
    # https://github.com/dchbx/enroll/blob/643b132a7bb150ebc05ec8f6ffaf370b2b97e2d2/app/controllers/concerns/vlp_doc.rb#L18
    # but needed restructuring to preven tother failures
    if (params[source][:naturalized_citizen] == "true" && params[source][:naturalized_citizen].present?)
      return false
    end
    if (params[source][:eligible_immigration_status] == "true" && params[source][:naturalized_citizen].present?)
      return false
    end
    # If none of the above conditions are false, run the validations
    true
  end

  def validate_vlp_params?(params, source, consumer_role, dependent)
    params.permit!
    if run_validate_vlp_params?(params, source, consumer_role)
      if params[source][:consumer_role].present? && params[source][:consumer_role][:vlp_documents_attributes].present?
        vlp_doc_params = params[source][:consumer_role][:vlp_documents_attributes]['0'].to_h.delete_if {|k,v| v.blank? }
        result = ::Validators::VlpV37Contract.new.call(vlp_doc_params)
        if result.failure? && source == 'person'
          invalid_key = result.errors.to_h.keys.first
          invalid_field = (invalid_key == :description) ? :document_description : invalid_key
          add_document_errors_to_consumer_role(consumer_role, ['Please fill in your information for', invalid_field.to_s.titlecase + '.'])
          return false
        elsif result.failure? && source == 'dependent'
          invalid_key = result.errors.to_h.keys.first
          invalid_field = (invalid_key == :description) ? :document_description : invalid_key
          add_document_errors_to_dependent(dependent, ['Please fill in your information for', invalid_field.to_s.titlecase + '.'])
          return false
        end
      end
    end
    # Return true if validations are not run
    true
  end


  def update_vlp_documents?(consumer_role, source = 'person', dependent = nil)
    return true if consumer_role.blank?
    return false unless validate_vlp_params?(params, source, consumer_role, dependent)
    if (params[source][:naturalized_citizen] == "true" || params[source][:eligible_immigration_status] == "true") &&
      (params[source][:consumer_role].blank? || params[source][:consumer_role][:vlp_documents_attributes].blank?)
      if source == 'person'
        add_document_errors_to_consumer_role(consumer_role, ["document type", "cannot be blank"])
      elsif source == 'dependent' && dependent.present?
        add_document_errors_to_dependent(dependent, ["document type", "cannot be blank"])
      end
      return false
    end
    if params[source][:consumer_role] && params[source][:consumer_role][:vlp_documents_attributes]
        if params[:dependent].present? && params[:dependent][:consumer_role][:vlp_documents_attributes]["0"].present? && params[:dependent][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date].present?
          params[:dependent][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date] = DateTime.strptime(params[:dependent][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date], '%m/%d/%Y')
      elsif params[:person].present? && params[:person][:consumer_role].present? && params[:person][:consumer_role][:vlp_documents_attributes]["0"].present? && params[:person][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date].present?
        params[:person][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date] = DateTime.strptime(params[:person][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date], "%m/%d/%Y")
      end

      doc_params = params.require(source).permit(*vlp_doc_params_list)
      vlp_doc_attribute = doc_params[:consumer_role][:vlp_documents_attributes]["0"]
      if vlp_doc_attribute
        document = consumer_role.find_document(vlp_doc_attribute[:subject])
        document.update_attributes(vlp_doc_attribute)
        consumer_role.update_attributes!(active_vlp_document_id: document.id) if document.present?
      end
      if source == 'person'
        add_document_errors_to_consumer_role(consumer_role, document)
      elsif source == 'dependent' && dependent.present?
        add_document_errors_to_dependent(dependent, document)
      end
      if document.present?
        return document.errors.blank?
      else
        return false
      end
    else
      return true
    end
  end

  def get_vlp_doc_subject_by_consumer_role(consumer_role)
    consumer_role&.vlp_documents&.where(id: consumer_role.active_vlp_document_id)&.first&.subject
  end

  def sensitive_info_changed?(role)
    if role
      params_hash = params.permit!.to_h
      info_changed = role.sensitive_information_changed?(params_hash[:person] || params_hash[:dependent])
      dc_status = role.person.no_dc_address
      return info_changed, dc_status
    end
  end

  def native_status_changed?(role)
    if role
      params_hash = params.permit!.to_h
      role.person.send("tribal_id") != params_hash["tribal_id"]
    end
  end
end