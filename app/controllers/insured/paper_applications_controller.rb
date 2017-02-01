class Insured::PaperApplicationsController < ApplicationController
  include ApplicationHelper

  before_action :get_family
  before_action :updateable?, only: [:upload]

  def upload
    if params[:file].nil?
      flash[:error] = "File not uploaded. Please select the file to upload."
      redirect_to upload_application_insured_families_path
      return
    end

    @doc_errors = []
    @docs_owner = find_docs_owner(params[:family_member])

    if params[:file]
      doc_uri = Aws::S3Storage.save(file_path(params[:file]), 'id-verification')
      if doc_uri.present? && @docs_owner.resident_role? && update_paper_application(file_name(params[:file]), doc_uri)
        flash[:notice] = "File Saved"
      else
        flash[:error] = "Could not save file. " + @doc_errors.join(". ")
      end
    else
        flash[:error] = "Could not save file"
    end
    redirect_to upload_application_insured_families_path
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
    #vlp_docs_clean(@person)
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

  def person_resident_role
    @person.resident_role
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

  def update_paper_application(title, file_uri)
    application = @docs_owner.resident_role.paper_applications.build
    success = application.update_attributes({:identifier=>file_uri, :subject => title, :title=>title, :status=>"downloaded"})
    @doc_errors = document.errors.full_messages unless success
    @docs_owner.save
  end

  def get_document(key)
    @person.resident_role.find_paper_application_by_key(key)
  end

  def download_options(document)
    options = {}
    options[:content_type] = document.format
    options[:filename] = document.title
    options
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
