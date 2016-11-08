# Report: Rake task to find duplicate users account
# To Run Rake Task: RAILS_ENV=production rake report:user_account:duplicate_users
require 'csv'

namespace :report do
  namespace :user_account do

    desc "List of users with same user account"
    task :duplicate_users => :environment do
      all_dups = User.collection.aggregate([{'$project': {oim_id: {"$toLower" => '$oim_id'}}},{'$group': {_id: '$oim_id', count: {'$sum':1}}},{ '$match': { count: { '$gt': 1 } }}]).entries
      field_names  = %w(
               username
               user_email
               person_email
               person_hbx_id
               user_first_name
               user_last_name
               created_at
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/duplicate_users.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        all_dups.each do |dup|
          users= User.where(:oim_id => Regexp.new("^#{dup['_id']}$",true))
          users.each do |user|
            csv << [
                user.oim_id,
                user.email,
                user.try(:person).try(:work_email_or_best),
                user.try(:person).try(:hbx_id),
                user.try(:person).try(:first_name),
                user.try(:person).try(:last_name),
                user.created_at
            ]
            processed_count += 1
          end
        end
        puts "Duplicate users account output file: #{file_name} "
      end
   end
  end
  end