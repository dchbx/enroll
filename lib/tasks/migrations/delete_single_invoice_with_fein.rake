require File.join(Rails.root, "app", "data_migrations", "delete_single_invoice_with_fein")
# RAILS_ENV=production bundle exec rake migrations:delete_single_invoice_with_fein fein="843628239" date="12/15/2017"

namespace :migrations do
  desc "delete current month invoice for given fein"
  DeleteSingleInvoiceWithFein.define_task :delete_single_invoice_with_fein => :environment
end
