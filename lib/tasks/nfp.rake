namespace :nfp do
  desc "Upload invoice to and associate with employer"
  task invoice_upload: :environment do
    invoice_folder = "invoices"
    current_month_folder = TimeKeeper.date_of_record.strftime("%b-%Y")
    absolute_folder_path = File.expand_path("#{invoice_folder}/#{current_month_folder}")

    if Dir.exists?(absolute_folder_path)
      Dir.entries(absolute_folder_path).each do |file|
        next if File.directory?(file) #skipping directories
        org = Organization.by_invoice_filename(absolute_folder_path+"/"+file)
        if org.present?
          puts "uploading file #{absolute_folder_path}/#{file}"
          Organization.upload_invoice(absolute_folder_path+"/"+file,file)
          org.employer_profile.trigger_notices("employer_invoice_available")#send invoice available notice to ERs.
        end
      end
    else
      puts "Folder #{absolute_folder_path} doesn't exist. Please check and rerun the rake"
    end
  end
end
