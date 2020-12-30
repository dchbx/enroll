# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'delete_uploaded_files')
# This will delete the uploaded file objects(VLP Document model under Consumer Role)
# and also generates a csv file containing information about the Person
# RAILS_ENV=production bundle exec rake migrations:delete_uploaded_files

namespace :migrations do
  desc 'updates the field active_vlp_document_id with the active VLP Document for the person'
  DeleteUploadedFiles.define_task :delete_uploaded_files => :environment
end
