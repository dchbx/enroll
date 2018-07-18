module SponsoredBenefits
  module Documents
    class Invoice < Document



      def self.upload_invoice(file_path,file_name)
        invoice_date = invoice_date(file_path) rescue nil
        org = by_invoice_filename(file_path) rescue nil
        if invoice_date && org && !invoice_exist?(invoice_date,org)
          doc_uri = Aws::S3Storage.save(file_path, "invoices",file_name)
          if doc_uri
            document = Document.new
            document.identifier = doc_uri
            document.date = invoice_date
            document.format = 'application/pdf'
            document.subject = 'invoice'
            document.title = File.basename(file_path)
            org.documents << document
            logger.debug "associated file #{file_path} with the Organization"
            return document
          end
        else
          logger.warn("Unable to associate invoice #{file_path}")
        end
      end

      def self.upload_invoice_to_print_vendor(file_path,file_name)
        org = by_invoice_filename(file_path) rescue nil
        if org.employer_profile.is_converting?
          bucket_name= Settings.paper_notice
          begin
            doc_uri = Aws::S3Storage.save(file_path,bucket_name,file_name)
          rescue Exception => e
            puts "Unable to upload invoices to paper notices bucket"
          end
        end
      end

      # Expects file_path string with file_name format /hbxid_mmddyyyy_invoices_r.pdf
      # Returns Organization
      def self.by_invoice_filename(file_path)
        hbx_id= File.basename(file_path).split("_")[0]
        Organization.where(hbx_id: hbx_id).first
      end

      # Expects file_path string with file_name format /hbxid_mmddyyyy_invoices_r.pdf
      # Returns Date
      def self.invoice_date(file_path)
        date_string= File.basename(file_path).split("_")[1]
        Date.strptime(date_string, "%m%d%Y")
      end

      def self.invoice_exist?(invoice_date,org)
        docs =org.documents.where("date" => invoice_date)
        matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}"))}
        return true if matching_documents.count > 0
      end


    end
  end
end
