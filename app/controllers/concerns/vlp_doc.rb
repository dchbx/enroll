module VlpDoc
  include ErrorBubble
  def vlp_doc_params_list
    [
      {:consumer_role =>
       [:vlp_documents_attributes =>
        [:subject, :citizenship_number, :naturalization_number,
         :alien_number, :passport_number, :sevis_id, :visa_number,
         :receipt_number, :expiration_date, :card_number,
         :i94_number, :country_of_citizenship]]}
    ]
  end

  def validate_vlp_params(params, source, consumer_role, dependent)
    params.permit!
    if params[source][:consumer_role].present? && params[source][:consumer_role][:vlp_documents_attributes].present?
      result = ::Validators::VlpV37Contract.new.call(params[source][:consumer_role][:vlp_documents_attributes]['0'].to_h)
      if result.failure? && source == 'person'
        add_document_errors_to_consumer_role(consumer_role, [result.errors.to_h.keys.first.to_s.titlecase, result.errors.to_h.values.flatten.first])
        return false
      elsif result.failure? && source == 'dependent'
        add_document_errors_to_dependent(dependent, [result.errors.to_h.keys.first.to_s.titlecase, result.errors.to_h.values.flatten.first])
        return false
      end
    end
    true
  end

  def update_vlp_documents(consumer_role, source = 'person', dependent = nil)
    return true if consumer_role.blank?
    return true if params[source][:is_applying_coverage] == "false"
    return false unless validate_vlp_params(params, source, consumer_role, dependent)

    if (params[source][:naturalized_citizen] == "true" || params[source][:eligible_immigration_status] == "true") && (params[source][:consumer_role].blank? || params[source][:consumer_role][:vlp_documents_attributes].blank?)
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
      document = consumer_role.find_document(vlp_doc_attribute[:subject])
      document.update_attributes(vlp_doc_attribute)
      if source == 'person'
        add_document_errors_to_consumer_role(consumer_role, document)
      elsif source == 'dependent' && dependent.present?
        add_document_errors_to_dependent(dependent, document)
      end
      return document.errors.blank?
    else
      return true
    end
  end

  def get_vlp_doc_subject_by_consumer_role(consumer_role)
    return nil if consumer_role.blank? || consumer_role.vlp_documents.empty?
    naturalized_citizen_docs = ["Certificate of Citizenship", "Naturalization Certificate"]
    docs_for_status = consumer_role.citizen_status == "naturalized_citizen" ? naturalized_citizen_docs : VlpDocument::VLP_DOCUMENT_KINDS
    docs_for_status_uploaded = consumer_role.vlp_documents.where(:subject => {"$in" => docs_for_status})
    docs_for_status_uploaded.any? ? docs_for_status_uploaded.order_by(:updated_at => 'desc').first.subject : nil
  end

  def sensitive_info_changed?(role)
    if role
      params_hash = params.permit!.to_h
      info_changed = role.sensitive_information_changed?(params_hash[:person] || params_hash[:dependent])
      dc_status = role.person.no_dc_address
      return info_changed, dc_status
    end
  end
end
