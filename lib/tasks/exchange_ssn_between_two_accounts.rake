require File.join(Rails.root, "app", "data_migrations", "exchange_ssn_between_two_accounts")

#this rake task is used to exchange the ssn of two people accounts
#RAILS_ENV=production rake migrations:exchange_ssn_between_two_accounts hbx_id_1="123123" hbx_id_2="321312312"

namespace :migrations do
  desc 'exchange the ssns between two accounts'
  ExchangeSsnBetweenTwoAccounts.define_task :exchange_ssn_between_two_accounts => :environment
end


