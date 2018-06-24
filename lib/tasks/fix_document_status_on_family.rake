require File.join(Rails.root, "app", "data_migrations", "fix_document_status_on_family")
# RAILS_ENV=production bundle exec rake migrations:fix_document_status_on_family  hbx_ids="3334c58c4afc40c2a5c191403688b4c7"

namespace :migrations do
  desc "update document status on family"
  FixDocumentStatus.define_task :fix_document_status_on_family => :environment
end