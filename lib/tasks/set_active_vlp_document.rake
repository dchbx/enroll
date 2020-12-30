# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'set_active_vlp_document')
# This will update Consumer Role for Active VLP Document and also generates a csv file containing information about the updated Person
# RAILS_ENV=production bundle exec rake migrations:set_active_vlp_document

namespace :migrations do
  desc 'updates the field active_vlp_document_id with the active VLP Document for the person'
  SetActiveVlpDocument.define_task :set_active_vlp_document => :environment
end
