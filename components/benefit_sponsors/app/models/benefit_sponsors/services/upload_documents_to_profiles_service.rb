module BenefitSponsors
  module Services
    class UploadDocumentsToProfilesService

      def fetch_date(file_path)
        date_string = File.basename(file_path).split("_")[1]
        Date.strptime(date_string, "%m%d%Y")
      end

      def commission_statement_exist?(statement_date,org)
        docs = org.broker_agency_profile.documents.where("date" => statement_date)
        matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}_\\d{6,8}_COMMISSION"))}
        return true if matching_documents.count > 0
      end

      def by_commission_statement_filename(file_path)
        npn = File.basename(file_path).split("_")[0]
        BrokerRole.find_by_npn(npn).broker_agency_profile.organization
      end

      def upload_commission_statement(file_path,file_name)
        statement_date = fetch_date(file_path) rescue nil
        org = by_commission_statement_filename(file_path) rescue nil
        if statement_date && org && !commission_statement_exist?(statement_date,org)
          doc_uri = Aws::S3Storage.save(file_path, "commission-statements", file_name)
          if doc_uri
            document = BenefitSponsors::Documents::Document.new
            document.identifier = doc_uri
            document.date = statement_date
            document.format = 'application/pdf'
            document.subject = 'commission-statement'
            document.title = File.basename(file_path)
            org.broker_agency_profile.documents << document
            Rails.logger.debug "associated commission statement #{file_path} with the Organization"
            return document
          end
        else
          Rails.logger.warn("Unable to associate commission statement #{file_path}")
        end
      end

      def upload_invoice_to_employer_profile(file_path,file_name)
        invoice_date = fetch_date(file_path) rescue nil
        org = by_invoice_filename(file_path) rescue nil
        if invoice_date && org && !invoice_exist?(invoice_date,org)
          doc_uri = ::Aws::S3Storage.save(file_path, "invoices", file_name)
          if doc_uri
            document = BenefitSponsors::Documents::Document.new
            document.identifier = doc_uri
            document.date = invoice_date
            document.format = 'application/pdf'
            document.subject = 'invoice'
            document.title = File.basename(file_path)
            org.employer_profile.documents << document
            Rails.logger.debug "associated file #{file_path} with the Organization"
            return document
          else
            @errors << "Unable to upload PDF to AWS S3 for #{org.hbx_id}"
            Rails.logger.warn("Unable to upload PDF to AWS S3")
          end
        else
          Rails.logger.warn("Unable to associate invoice #{file_path}")
        end
      end

      def invoice_exist?(invoice_date,org)
        docs = org.employer_profile.invoices.select{|doc| doc.date == invoice_date }
        matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}"))}
        return true if matching_documents.count > 0
      end

      def by_invoice_filename(file_path)
        hbx_id = File.basename(file_path).split("_")[0]
        BenefitSponsors::Organizations::Organization.where(hbx_id: hbx_id).first
      end

    end
  end
end