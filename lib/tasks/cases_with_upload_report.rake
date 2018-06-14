require File.join(Rails.root, "app", "reports", "cases_with_upload_report")

namespace :reports do
  desc "Update Hbx enrollments review status attribute"
  CasesWithUploadReport.define_task :cases_with_upload_report => :environment
end