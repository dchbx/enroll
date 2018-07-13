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
        service = BenefitSponsors::Services::UploadDocumentsToProfilesService.new
        service.upload_invoice_to_employer_profile(file_join_path,file)
        # It will fetch organization
        organization = service.by_invoice_filename(file_join_path)
      end
    else
      puts "Folder #{absolute_folder_path} doesn't exist. Please check and rerun the rake"
    end
  end
end
