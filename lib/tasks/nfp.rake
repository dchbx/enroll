# This will upload the invoice to S3 and trigger notice
# To Run this Rake we have to pass invoice path as argument
# For Ex: RAILS_ENV=production bundle exec rake nfp:invoice_upload['/home/premshaganti/Downloads/invoices/']
namespace :nfp do
  desc "Upload invoice to and associate with employer"
  task :invoice_upload, [:invoice_path] => :environment do |task, args|
    absolute_folder_path = args.invoice_path
    if Dir.exists?(absolute_folder_path)
      Dir.entries(absolute_folder_path).each do |file|
        next if File.directory?(file) #skipping directories
        puts "uploading file #{absolute_folder_path}/#{file}" unless Rails.env.test?
        file_join_path = File.join(absolute_folder_path, file)
        # It will upload file to s3
        Organization.upload_invoice(file_join_path,file)
        # It will fetch organization
        organization = Organization.by_invoice_filename(file_join_path)
        # It will trigger notice
        trigger_notice_for_employer(organization) if organization.present?
      end
    else
      puts "Folder #{absolute_folder_path} doesn't exist. Please check and rerun the rake"
    end
  end

  def trigger_notice_for_employer(org)
    observer = Observers::Observer.new
    plan_year = org.employer_profile.active_plan_year
    observer.trigger_notice(recipient: org.employer_profile, event_object: plan_year, notice_event: "employer_invoice_available") if plan_year.present?
  end
end
