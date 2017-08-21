require File.join(Rails.root, "app", "data_migrations", "update_book_mark_url_for_employee_role")
# This rake task is to update employee role book mrk url
# RAILS_ENV=production bundle exec rake migrations:update_book_mark_url_for_employee_role employee_role_id=5835bff6082e7645b70000de bookmark_url="https://enroll.healthlink.com"
namespace :migrations do
  desc "Update Book mark URL"
  UpdateBookMarkUrlForEmployeerole.define_task :update_book_mark_url_for_employee_role => :environment
end 
