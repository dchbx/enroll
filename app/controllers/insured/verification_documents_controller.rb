class Insured::VerificationDocumentsController < ApplicationController
  include ApplicationHelper

  before_action :get_family
  before_action :updateable?, only: [:upload]

  def upload
    @doc_errors = []
    @docs_owner = find_docs_owner(params[:family_member])
    if params[:file]
      params[:file].each do |file|
        doc_uri = Aws::S3Storage.save(file_path(file), 'id-verification')
        if doc_uri.present?
          if update_vlp_documents(file_name(file), doc_uri)
            add_type_history_element(file)
            @family.update_family_document_status!
            flash[:notice] = "File Saved"
          else
            flash[:error] = "Could not save file. " + @doc_errors.join(". ")
            redirect_to(:back)
            return
          end
        else
          flash[:error] = "Could not save file"
        end
      end
    else
      flash[:error] = "File not uploaded. Please select the file to upload."
    end
    redirect_to verification_insured_families_path
  end

  def download
    document = get_document(params[:key])
    if document.present?
      bucket = env_bucket_name('id-verification')
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{params[:key]}"
      send_data Aws::S3Storage.find(uri), download_options(document)
    else
      flash[:error] = "File does not exist or you are not authorized to access it."
      redirect_to verification_insured_families_path
    end
    vlp_docs_clean(@person)
  end

  private
  def updateable?
    authorize Family, :updateable?
  end

  def get_family
    set_current_person
    @family = @person.primary_family
  end

  def person_consumer_role
    @person.consumer_role
  end

  def file_path(file)
    file.tempfile.path
  end

  def file_name(file)
    file.original_filename
  end

  def find_docs_owner(id)
    @person.primary_family.family_members.find(id).person
  end

  def update_vlp_documents(title, file_uri)
    v_type = params[:verification_type]
    document = @docs_owner.consumer_role.vlp_documents.build
    success = document.update_attributes({:identifier=>file_uri, :subject => title, :title=>title, :status=>"downloaded", :verification_type=>v_type})
    @docs_owner.consumer_role.mark_doc_type_uploaded(v_type)
    @doc_errors = document.errors.full_messages unless success
    @docs_owner.save
  end

  def update_paper_application(title, file_uri)

    document = @docs_owner.resident_role.vlp_documents.build
    success = document.update_attributes({:identifier=>file_uri, :subject => title, :title=>title, :status=>"downloaded", :verification_type=>params[:verification_type]})
    @doc_errors = document.errors.full_messages unless success
    @docs_owner.save
  end

  def get_document(key)
    @person.consumer_role.find_vlp_document_by_key(key)
  end

  def download_options(document)
    options = {}
    options[:content_type] = document.format
    options[:filename] = document.title
    options
  end

  def add_type_history_element(file)
    actor = current_user ? current_user.email : "external source or script"
    verification_type = params[:verification_type]
    action = "Upload #{file_name(file)}" if params[:action] == "upload"
    @docs_owner.consumer_role.add_type_history_element(verification_type: verification_type,
                                                   action: action,
                                                   modifier: actor)
  end

  def vlp_docs_clean(person)
    existing_documents = person.consumer_role.vlp_documents
    person_consumer_role=Person.find(person.id).consumer_role
    person_consumer_role.vlp_documents =[]
    person_consumer_role.save
    person_consumer_role=Person.find(person.id).consumer_role
    person_consumer_role.vlp_documents = existing_documents.uniq
    person_consumer_role.save
  end

end
