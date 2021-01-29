class DocumentsController < ApplicationController
  before_action :updateable?, except: [:show_docs, :download]
  before_action :set_document, only: [:destroy, :update]
  before_action :set_verification_type
  before_action :set_person, only: [:enrollment_docs_state, :fed_hub_request, :enrollment_verification, :update_verification_type, :extend_due_date, :update_ridp_verification_type]
  before_action :add_type_history_element, only: [:update_verification_type, :fed_hub_request, :destroy]
  respond_to :html, :js

  def download
    bucket = params[:bucket]
    key = params[:key]
    uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
    send_data Aws::S3Storage.find(uri), get_options(params)
  end

  def download_employer_document
    document = BenefitSponsors::Documents::EmployerAttestationDocument.find_by(identifier: params[:path])
    document.present? ? (send_file document.identifier) : redirect_back(fallback_location: root_path, :flash => {error: "Document Not Found"})
  rescue StandardError => e
    redirect_back(fallback_location: root_path, :flash => {error: e.message})
  end

  def authorized_download
    begin
      model = params[:model].camelize
      model_id = params[:model_id]
      relation = ["documents"].include?(params[:relation]) ? params[:relation] : "documents"
      relation_id = params[:relation_id]

      #this is a fix for new model inbox-messages notice download
      if model == "AcaShopCcaEmployerProfile"
        model = "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile"
      end
      model_klass = Document::RESOURCE_LIST.include?(model) ? model.safe_constantize : nil
      raise "Sorry! Invalid Request" unless model_klass

      model_object = model_klass.find(model_id)
      documents = model_object.send(relation.to_sym)
      if authorized_to_download?(model_object, documents, relation_id)
        uri = documents.find(relation_id).identifier
        send_data Aws::S3Storage.find(uri), get_options(params)
      else
       raise "Sorry! You are not authorized to download this document."
      end
    rescue => e
      redirect_back(fallback_location: root_path, :flash => {error: e.message})
    end
  end

  def cartafact_download
    result = ::Operations::Documents::Download.call({params: params.permit!.to_h, user: current_user})
    if result.success?
      response_data = result.value!
      send_data response_data, get_options(params)
    else
      errors = result.failure
      redirect_back(fallback_location: root_path, :flash => {error: errors[:message]})
    end
  rescue StandardError => e
    redirect_back(fallback_location: root_path, :flash => {error: e.message})
  end

  def update_verification_type
    update_reason = params[:verification_reason]
    admin_action = params[:admin_action]
    family_member = FamilyMember.find(params[:family_member_id]) if params[:family_member_id].present?
    reasons_list = VlpDocument::VERIFICATION_REASONS + VlpDocument::ALL_TYPES_REJECT_REASONS + VlpDocument::CITIZEN_IMMIGR_TYPE_ADD_REASONS
    if (reasons_list).include? (update_reason)
      verification_result = @person.consumer_role.admin_verification_action(admin_action, @verification_type, update_reason)
      message = (verification_result.is_a? String) ? verification_result : "Person verification successfully approved."
      flash_message = { :success => message}
      update_documents_status(family_member) if family_member
    else
      flash_message = { :error => "Please provide a verification reason."}
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, :flash => flash_message) }
    end
  end

  def update_ridp_verification_type
    ridp_type = params[:ridp_verification_type]
    update_reason = params[:verification_reason]
    admin_action = params[:admin_action]
    if (RidpDocument::VERIFICATION_REASONS + RidpDocument::RETURNING_FOR_DEF_REASONS).include? (update_reason)
      verification_result = @person.consumer_role.admin_ridp_verification_action(admin_action, ridp_type, update_reason)
      message = (verification_result.is_a? String) ? verification_result : "Person verification successfully approved."
      flash_message = { :success => message}
    else
      flash_message = { :error => "Please provide a verification reason."}
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: '/', :flash => flash_message }
    end
  end

  def enrollment_verification
     family = @person.primary_family
     if family.active_household.hbx_enrollments.verification_needed.any?
       family.active_household.hbx_enrollments.verification_needed.each do |enrollment|
         enrollment.evaluate_individual_market_eligiblity
       end
       family.save!
       respond_to do |format|
         format.html {
           flash[:success] = "Enrollment group was completely verified."
           redirect_back(fallback_location: root_path)
         }
       end
     else
       respond_to do |format|
         format.html {
           flash[:danger] = "Family does not have any active Enrollment to verify."
           redirect_back(fallback_location: root_path)
         }
       end
     end
  end

  def fed_hub_request
    request_hash = {person_id: @person.id, verification_type: @verification_type.type_name}
    result = ::Operations::CallFedHub.new.call(request_hash)
    key, message = result.failure? ? result.failure : result.success

    respond_to do |format|
      format.html {
        flash[key] = message
        redirect_back(fallback_location: root_path)
      }
      format.js
    end
  end

  def show_docs
    if current_user.has_hbx_staff_role?
      session[:person_id] = params[:person_id]
      set_current_person
      @person.primary_family.active_household.hbx_enrollments.verification_needed.each do |enrollment|
        enrollment.update_attributes(:review_status => "in review")
      end
    end
    redirect_to verification_insured_families_path
  end

  def extend_due_date
    @family_member = FamilyMember.find(params[:family_member_id])
    enrollment = @family_member.family.enrollments.verification_needed.where(:"hbx_enrollment_members.applicant_id" => @family_member.id).first
    if enrollment.present?
      new_date = @verification_type.verif_due_date + 30.days
      updated = @verification_type.update_attributes(:due_date => new_date)
      if updated
        flash[:success] = "#{@verification_type.type_name} verification due date was extended for 30 days."
        set_min_due_date_on_family
        add_type_history_element
      end
    else
      flash[:danger] = "Family Member does not have any unverified Enrollment to extend verification due date."
    end
    redirect_back(fallback_location: root_path)
  end

  def destroy
    @document.delete if @verification_type.type_unverified?
    if @document.destroyed?
      @person.save!
      if (@verification_type.vlp_documents - [@document]).empty?
        @verification_type.update_attributes(:validation_status => "outstanding", :update_reason => "all documents deleted")
        flash[:danger] = "All documents were deleted. Action needed"
      else
        flash[:success] = "Document deleted."
      end
    else
      flash[:danger] = "Document can not be deleted because type is verified."
    end
    respond_to do |format|
      format.html { redirect_to verification_insured_families_path }
      format.js
    end
  end

  def new
    @document = Document.new
    respond_to do |format|
      format.js
    end
  end

  def create
    @employer_profile = Organization.all_employer_profiles.where(legal_name: params[:document][:creator]).last.employer_profile
    @employer_profile.employer_attestation= EmployerAttestation.new() unless @employer_profile.employer_attestation
    #@employer_profile.employer_attestation.employer_attestation_doccument = EmployerAttestationDocument.new() unless @employer_profile.employer_attestation.employer_attestation_doccument
    document = @employer_profile.employer_attestation.upload_document(file_path(params[:file]),file_name(params[:file]),params[:subject],params[:file].size)
    if document.save!
      @employer_profile.employer_attestation.update_attributes(aasm_state: "submitted")
    end
    redirect_to exchanges_hbx_profiles_path+'?tab=documents'
  end

  def document_reader
    content = @document.source.read
    if stale?(etag: content, last_modified: @user.updated_at.utc, public: true)
      send_data content, type: @document.source.file.content_type, disposition: "inline"
      expires_in 0, public: true
    end
  end

  def download_documents
    docs = Document.find(params[:ids])
    docs.each do |doc|
      send_file "#{Rails.root}"+"/tmp" + doc.source.url, file_name: doc.title, :type=>"application/pdf"
    end

  end

  def delete_documents
    begin
      Document.any_in(:_id =>params[:ids]).destroy_all
      render json: { status: 200, message: 'Successfully submitted the selected employer(s) for binder paid.' }
    rescue => e
      render json: { status: 500, message: 'An error occured while submitting employer(s) for binder paid.' }
    end
  end

  def update_document
    @document = EmployerProfile.find(params[:document_id]).employer_attestation
    @reason = params[:reason_for_rejection] == "nil" ? params[:other_reason] : params[:reason_for_rejection]
    @document.employer_attestation_documents.find(params[:attestation_doc_id]).update_attributes(aasm_state: params[:status],reason_for_rejection: @reason)
    @document.update_attributes(aasm_state: params[:status])

    redirect_to exchanges_hbx_profiles_path+'?tab=documents'
  end

  def add_type_history_element
    actor = current_user ? current_user.email : "external source or script"
    action = params[:admin_action] || params[:action]
    action = "Delete #{params[:doc_title]}" if action == "destroy"
    reason = params[:verification_reason]
    if @verification_type
      @verification_type.add_type_history_element(action: action.split('_').join(' '),
                                                  modifier: actor,
                                                  update_reason: reason)
    end
  end

  private

  def updateable?
    authorize Family, :updateable?
  end

  def get_options(params)
    options = {}
    options[:content_type] = params[:content_type] if params[:content_type]
    options[:filename] = params[:filename] if params[:filename]
    options[:disposition] = params[:disposition] if params[:disposition]
    options
  end

  def authorized_to_download?(owner, documents, document_id)
    return true
    owner.user.has_hbx_staff_role? || documents.find(document_id).present?
  end

  def update_documents_status(family_member)
    family = family_member.family
    family.update_family_document_status!
  end

  def set_document
    set_verification_type
    @document = @verification_type.vlp_documents.find(params[:id])
  end

  def set_person
    @person = Person.find(params[:person_id]) if params[:person_id]
  end

  def set_verification_type
    set_person
    @verification_type = @person.verification_types.active.find(params[:verification_type]) if params[:verification_type]
  end

  def verification_attr
    OpenStruct.new({:determined_at => Time.now,
                    :authority => "hbx"
                   })
  end

  def file_path(file)
    file.tempfile.path
  end

  def file_name(file)
    file.original_filename
  end

  def set_min_due_date_on_family
    family = @family_member.family
    family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family)
  end
end
