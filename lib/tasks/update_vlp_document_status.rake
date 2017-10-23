namespace :families do
  desc "update vlp document status"
  task :update_vlp_documents_status => :environment do 
   Family.each do |f|
      f.update_family_document_status!
   end
  puts "All families are updated with vlp document status"
  end
end