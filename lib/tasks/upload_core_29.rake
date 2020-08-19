require File.join(Rails.root, "app", "data_migrations", "upload_faa")

namespace :migrations do
  desc "upload FAA from CSV"
  UploadFAA.define_task :upload_core_29 => :environment
end
