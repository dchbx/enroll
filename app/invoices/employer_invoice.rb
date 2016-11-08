class EmployerInvoice
  include InvoiceHelper

  attr_reader :errors

  def initialize(organization,folder_name=nil)
    @organization= organization
    @employer_profile= organization.employer_profile
    @hbx_enrollments=@employer_profile.enrollments_for_billing
    @folder_name = folder_name
    @errors=[]
  end

  def pdf_doc
    @pdf_doc ||= build_pdf
  end

  def save
    begin
      unless File.directory?(invoice_folder_path)
        FileUtils.mkdir_p(invoice_folder_path)
      end
      pdf_doc.render_file(invoice_absolute_file_path) unless File.exist?(invoice_absolute_file_path)
    rescue Exception => e
      @errors << "Unable to create PDF for #{@organization.hbx_id}."
      @errors << e.inspect
    end
  end

  def save_to_cloud
    begin
      Organization.upload_invoice(invoice_absolute_file_path,invoice_file_name)
    rescue Exception => e
      @errors << "Unable to upload PDF for. #{@organization.hbx_id}"
      Rails.logger.warn("Unable to create PDF #{e} #{e.backtrace}")
    end
	end

  def send_to_print_vendor
    begin
      Organization.upload_invoice_to_print_vendor(invoice_absolute_file_path,invoice_file_name)
    rescue Exception => e
      @errors << "Unable to send PDF to print vendor for. #{@organization.hbx_id}"
      Rails.logger.warn("Unable to create PDF #{e} #{e.backtrace}")
    end
  end

	def send_email_notice
    subject = "Invoice Now Available"
    body = "Your Renewal invoice is now available in your employer profile under Billing tab. Thank You"
    message_params = {
      sender_id: "admins",
      parent_message_id: @organization.employer_profile.id,
      from: "DC Health Link",
      to: "Employer Mailbox",
      subject: subject,
      body: body
    }
    create_secure_message message_params, @organization.employer_profile, :inbox
  end

  def clear_tmp(file)
    File.delete(file)
  end

	def save_and_notify_with_clean_up
		save
		save_to_cloud
    send_to_print_vendor
		send_email_notice
		clear_tmp(invoice_absolute_file_path)
	end

  def save_and_notify
    save
    save_to_cloud
    send_to_print_vendor
    send_email_notice
  end

  private

	def create_secure_message(message_params, inbox_provider, folder)
    message = Message.new(message_params)
    message.folder =  Message::FOLDER_TYPES[folder]
    msg_box = inbox_provider.inbox
    msg_box.post_message(message)
    msg_box.save
  end

  def current_month
    TimeKeeper.date_of_record.strftime("%b-%Y")
  end

  def invoice_folder_path
    if @folder_name
      Rails.root.join(@folder_name)
    else
      Rails.root.join('tmp',current_month)
    end
  end

  def invoice_absolute_file_path
    "#{invoice_folder_path}/#{invoice_file_name}"
  end

  def invoice_file_name
    "#{@organization.hbx_id}_#{TimeKeeper.datetime_of_record.strftime("%m%d%Y")}_INVOICE_R.pdf"
  end

end
