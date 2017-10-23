class Insured::RidpDocumentsController < ApplicationController
  include ApplicationHelper

  before_action :get_person
  before_action :updateable?, only: [:upload]
  before_action :set_document,  only: [:destroy]

  def upload
    @doc_errors = []
    @docs_owner = @person
    if params[:file]
      params[:file].each do |file|
        doc_uri =  "https://stackoverflow.com/questions/" #Aws::S3Storage.save(file_path(file), 'id-verification')
        if doc_uri.present?
          if update_ridp_documents(file_name(file), doc_uri)
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
    redirect_to(:back)
  end

  def download
    document = get_document(params[:key])
    if document.present?
      bucket = env_bucket_name('id-verification')
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{params[:key]}"
      send_data Aws::S3Storage.find(uri), download_options(document)
    else
      flash[:error] = "File does not exist or you are not authorized to access it."
      redirect_to(:back)
    end
    ridp_docs_clean(@person)
  end

  def destroy
    @document.delete
    respond_to do |format|
      format.js
    end
  end

  private
  def updateable?
    authorize Family, :updateable?
  end

  def get_person
    set_current_person
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


  def set_document
    @document = @person.consumer_role.ridp_documents.find(params[:id])
  end

  def update_ridp_documents(title, file_uri)
    ridp_type = params[:ridp_verification_type]
    document = @docs_owner.consumer_role.ridp_documents.build
    success = document.update_attributes({:identifier=>file_uri, :subject => title, :title=>title, :status=>"downloaded", :ridp_verification_type=>ridp_type, :uploaded_at => TimeKeeper.date_of_record})
    person_consumer_role.mark_ridp_doc_uploaded(ridp_type)
    @doc_errors = document.errors.full_messages unless success
    @docs_owner.save
  end

  def get_document(key)
    @person.consumer_role.find_ridp_document_by_key(key)
  end

  def download_options(document)
    options = {}
    options[:content_type] = document.format
    options[:filename] = document.title
    options
  end

  def ridp_docs_clean(person)
    existing_documents = person.consumer_role.ridp_documents
    person_consumer_role=Person.find(person.id).consumer_role
    person_consumer_role.ridp_documents =[]
    person_consumer_role.save
    person_consumer_role=Person.find(person.id).consumer_role
    person_consumer_role.ridp_documents = existing_documents.uniq
    person_consumer_role.save
  end

end
