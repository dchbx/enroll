#RAILS_ENV=production bundle exec rake migrations:remove_documents_associated_to_person hbx_id=3383180 message_id="5b52395bf209f24936000016"
require File.join(Rails.root, "app", "data_migrations", "remove_documents_associated_to_person")

 namespace :migrations do 
  desc "remove documents associated to person"
  RemoveDocumentsAssociatedToPerson.define_task :remove_documents_associated_to_person => :environment
end

# bundle exec rake migrations:remove_documents_associated_to_person hbx_id=f0d9adc7e05e426e8021c18c3b920ebd message_id="5bec4ab8f209f216f90000a7"