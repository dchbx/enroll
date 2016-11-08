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

  def update_vlp_documents(consumer_role, source='person', dependent=nil)

    return true if consumer_role.blank?

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
    return nil if consumer_role.blank?
    if [::ConsumerRole::NATURALIZED_CITIZEN_STATUS, ::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS].include? consumer_role.try(:person).try(:citizen_status)
      consumer_role.try(:vlp_documents).try(:last).try(:subject)
    end
  end
end
