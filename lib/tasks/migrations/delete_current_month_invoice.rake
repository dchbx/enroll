namespace :migrations do

  desc "delete current month invoice for given fein"
  task :delete_current_month_invoice => :environment do |t, args|
    DeleteInvoiceWithFein.migrate(ENV['FEINS'])
  end
end
