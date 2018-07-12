namespace :nfp do
  desc "Upload commission statements to S3 and associate with broker"
  task commission_statements_upload: :environment do
    invoice_folder = "commission_statements"
    current_month_folder = TimeKeeper.date_of_record.strftime("%b-%Y")
    absolute_folder_path = File.expand_path("#{invoice_folder}/#{current_month_folder}")

    if Dir.exists?(absolute_folder_path)
      Dir.entries(absolute_folder_path).each do |file|
        next if File.directory?(file) #skipping directories
        puts "uploading file #{absolute_folder_path}/#{file}"
        service = BenefitSponsors::Services::UploadDocumentsToProfilesService.new
        service.upload_commission_statement(absolute_folder_path+"/"+file,file)
      end
    else
      puts "Folder #{absolute_folder_path} doesn't exist. Please check and rerun the rake"
    end
  end
end