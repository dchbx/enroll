module Notifier
  module NoticeBuilder
    include Config::SiteConcern
    include Config::SiteHelper
    include ApplicationHelper
    include Notifier::ApplicationHelper

    def to_html(options = {})
      data_object = (resource.present? ? construct_notice_object : recipient.constantize.stubbed_object)
      render_envelope({recipient: data_object}) + render_notice_body({recipient_klass_name => data_object})
    end

    def notice_recipient
      return OpenStruct.new(hbx_id: "100009") if resource.blank?
      sub_resource? ? resource.person : resource
    end

    def construct_notice_object
      builder_klass = ['Notifier', 'Builders', recipient.split('::').last].join('::')
      builder = builder_klass.constantize.new
      builder.resource = resource
      builder.event_name = event_name if is_employee? || is_employer? || is_consumer?
      builder.payload = payload
      builder.append_contact_details
      builder.dependents if is_consumer?
      template.data_elements.each do |element|
        elements = element.split('.')
        next if is_consumer? && elements.first == 'dependent'

        date_element = elements.detect{|ele| Notifier::MergeDataModels::EmployerProfile::DATE_ELEMENTS.any?{|date| ele.match(/#{date}/i).present?}}

        if date_element.present?
          date_ele_index = elements.index(date_element)
          elements = elements[0..date_ele_index]
          elements[date_ele_index] = date_element.scan(/[a-zA-Z_]+/).first
        end
        element_retriver = elements.reject{|ele| ele == recipient_klass_name.to_s}.join('_')
        builder.instance_eval(element_retriver)
      end
      builder.merge_model
    end

    def render_envelope(params)
      template_location = if initial_invoice?
                            'notifier/notice_kinds/initial_invoice/invoice_template.html.erb'
                          else
                            envelope
                          end
       Notifier::NoticeKindsController.new.render_to_string({
        :template => template_location,
        :layout => false,
        :locals => params.merge(notice_number: self.notice_number, notice: self, notice_recipient: notice_recipient)
      })
    end

    def render_notice_body(params)
      Notifier::NoticeKindsController.new.render_to_string({
        :inline => template.raw_body.gsub('${', '<%=').gsub('#{', '<%=').gsub('}','%>').gsub('[[', '<%').gsub(']]', '%>'),
        :layout => layout,
        :locals => params
      })
    end

    def save_html
      File.open(Rails.root.join("tmp", "notice.html"), 'wb') do |file|
        file << execute_html_pdf_render
      end
    end

    def to_pdf
      WickedPdf.new.pdf_from_string(execute_html_pdf_render, pdf_options)
    end

    def generate_pdf_notice
      save_html
      File.open(notice_path, 'wb') do |file|
        file << self.to_pdf
      end

      if shop_market?
        attach_envelope
        non_discrimination_attachment
        # clear_tmp
      else
        ivl_blank_page
        ivl_non_discrimination
        ivl_taglines
        voter_application
      end
    end

    def pdf_options
      options = {
        margin: set_margin_for_market,
        disable_smart_shrinking: true,
        dpi: 96,
        page_size: 'Letter',
        formats: :html,
        encoding: 'utf8',
        header: {
          content: ApplicationController.new.render_to_string({
            template: header,
            layout: false,
            locals: {notice: self, recipient: notice_recipient}
            }),
          }
      }
      #TODO: Add footer partial
      if dc_exchange?
        options.merge!({footer: {
          content: ApplicationController.new.render_to_string({
            template: footer,
            layout: false,
            locals: {notice: self}
          })
        }})
      end
      options
    end

    def set_margin_for_market
      if is_consumer?
        {
          top: 10,
          bottom: 20,
          left: 22,
          right: 22
        }
      else
        {
          top: 15,
          bottom: 22,
          left: 22,
          right: 22
        }
      end
    end

    def notice_path
      Rails.root.join("tmp", "#{notice_filename}.pdf")
    end

    def subject
      title
    end

    def layout
      shop_market? ? Settings.notices.shop.partials.layout : Settings.notices.individual.partials.layout
    end

    def notice_filename
      "#{notice_recipient.hbx_id}_#{subject.titleize.gsub(/\s+/, '_')}"
    end

    def display_file_name
      "#{subject.titleize.gsub(/\s+/, '_')}"
    end

    def non_discrimination_attachment
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', shop_non_discrimination_attachment)]
    end

    def ivl_non_discrimination
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ivl_non_discrimination.pdf')]
    end

    def ivl_attach_envelope
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ivl_envelope.pdf')]
    end

    def voter_application
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'voter_application.pdf')] if ['projected_eligibility_notice'].include?(event_name)
    end

    def ivl_blank_page
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'blank.pdf')] if ['projected_eligibility_notice'].include?(event_name)
    end

    def attach_envelope
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', shop_envelope_without_address)]
    end

    def employee_appeal_rights
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'employee_appeal_rights.pdf')]
    end

    def ivl_taglines
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'taglines.pdf')]
    end

    def join_pdfs(pdfs)
      pdf = File.exists?(pdfs[0]) ? CombinePDF.load(pdfs[0]) : CombinePDF.new
      pdf << CombinePDF.load(pdfs[1])
      pdf.save notice_path
    end

    def upload_and_send_secure_message
      doc_uri = upload_to_amazonS3
      notice  = create_recipient_document(doc_uri)
      create_secure_inbox_message(notice)
    end

    def upload_to_amazonS3
      if initial_invoice?
        Aws::S3Storage.save(notice_path, 'invoices', file_name)
      else
        Aws::S3Storage.save(notice_path, 'notices')
      end
    rescue => e
      raise "unable to upload to amazon #{e}"
    end

    def file_name
      if initial_invoice?
        "#{resource.organization.hbx_id}_#{TimeKeeper.datetime_of_record.strftime('%m%d%Y')}_INVOICE_R.pdf"
      end
    end

    def invoice_date
      date_string = file_name.split("_")[1]
      Date.strptime(date_string, "%m%d%Y")
    end

    def recipient_name
      return nil unless recipient_target

      recipient_target.full_name.titleize
    end

    def recipient_to
      return nil unless recipient_target

      recipient_target.work_email_or_best
    end

    def is_employer?
      resource.is_a?("BenefitSponsors::Organizations::AcaShop#{site_key.capitalize}EmployerProfile".constantize) || resource.is_a?(BenefitSponsors::Organizations::FehbEmployerProfile)
    end

    def is_employee?
      resource.is_a?(EmployeeRole)
    end

    def is_consumer?
      resource.is_a?(ConsumerRole)
    end

    # @param recipient is a Person object
    def send_generic_notice_alert
      UserMailer.generic_notice_alert(recipient_name,subject,recipient_to).deliver_now unless has_valid_resource? && !resource.can_receive_electronic_communication?
    end

    def send_generic_notice_alert_to_broker_and_ga
      if is_employer?
        if resource.broker_agency_profile.present?
          broker_person = resource.broker_agency_profile.primary_broker_role.person
          broker_name = broker_person.full_name
          broker_email = broker_person.work_email_or_best
          UserMailer.generic_notice_alert_to_ba_and_ga(broker_name, broker_email, resource.legal_name.titleize).deliver_now
        end
        if resource.general_agency_profile.present?
          general_agency_staff_person = resource.general_agency_profile.primary_staff.person
          general_agent_name = general_agency_staff_person.full_name
          ga_email = general_agency_staff_person.work_email_or_best
          UserMailer.generic_notice_alert_to_ba_and_ga(general_agent_name, ga_email, resource.legal_name.titleize).deliver_now
        end
      end

      if is_employee?
        if resource.employer_profile.broker_agency_profile.present?
          broker_person = resource.employer_profile.broker_agency_profile.primary_broker_role.person
          broker_name = broker_person.full_name
          broker_email = broker_person.work_email_or_best
          UserMailer.generic_notice_alert_to_ba_and_ga(broker_name, broker_email, resource.person.full_name.titleize).deliver_now
        end
        if resource.employer_profile.general_agency_profile.present?
          general_agency_staff_person = resource.employer_profile.general_agency_profile.primary_staff.person
          general_agent_name = general_agency_staff_person.full_name
          ga_email = general_agency_staff_person.work_email_or_best
          UserMailer.generic_notice_alert_to_ba_and_ga(general_agent_name, ga_email, resource.person.full_name.titleize).deliver_now
        end
      end
    end

    def store_paper_notice
      return unless send_paper_notices? && has_valid_resource? && resource.can_receive_paper_communication?

      bucket_name = Settings.paper_notice
      notice_filename_for_paper_notice = if is_employer?
                                           "#{resource.organization.hbx_id}_#{subject.titleize.gsub(/\s+/, '')}_#{notice_number.delete('_')}_#{notice_type}"
                                         else
                                           "#{resource.person.hbx_id}_#{subject.titleize.gsub(/\s+/, '')}_#{notice_number.delete('_')}_#{notice_type}"
                                         end
      notice_path_for_paper_notice = Rails.root.join("tmp", "#{notice_filename_for_paper_notice}.pdf")
      begin
        FileUtils.cp(notice_path, notice_path_for_paper_notice)
        Aws::S3Storage.save(notice_path_for_paper_notice,bucket_name,"#{notice_filename_for_paper_notice}.pdf")
        File.delete(notice_path_for_paper_notice)
      rescue Exception => e
        puts "Unable to upload paper notices to Amazon"
      end
      # paper_notices_folder = "#{Rails.root.to_s}/public/paper_notices/"
      # FileUtils.cp(notice_path, "#{Rails.root.to_s}/public/paper_notices/")
      # File.rename(paper_notices_folder + , paper_notices_folder + "#{recipient.hbx_id}_" + notice_filename + File.extname(notice_path))
    end

    def create_recipient_document(doc_uri)
      receiver = resource
      receiver = resource.person if sub_resource?

      title = (event_name == 'generate_initial_employer_invoice') ? file_name : display_file_name

      doc_params = {
        title: title,
        creator: "hbx_staff",
        subject: document_subject,
        identifier: doc_uri,
        format: "application/pdf"
      }

      doc_params[:date] = invoice_date if initial_invoice?
      notice = receiver.documents.build(doc_params)

      if notice.save
        notice
      else
        # LOG ERROR
      end
    end

    def document_subject
      initial_invoice? ? 'initial_invoice' : 'notice'
    end

    def create_secure_inbox_message(notice)
      receiver = resource
      receiver = resource.person if sub_resource?

      if initial_invoice?
        body = "Your Initial invoice is now available in your employer profile under Billing tab. Thank You"
      else
        body = "<br>You can download the notice by clicking this link " +
               "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(receiver.class.to_s,
        receiver.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title.gsub(/[^0-9a-z]/i,'') + "</a>"
      end

      message = receiver.inbox.messages.build({ subject: subject, body: body, from: site_short_name })
      message.save!
    end

    def clear_tmp
      File.delete(notice_path)
    end

    def initial_invoice?
      self.event_name == 'generate_initial_employer_invoice'
    end

    def notice_type
      if is_consumer?
        "IVL"
      elsif is_employee?
        "EE"
      elsif is_employer?
        "ER"
      end
    end

    def has_valid_resource?
      (is_employee? || is_consumer? || is_employer?)
    end

    def sub_resource?
      (resource.is_a?(EmployeeRole) || resource.is_a?(BrokerRole) || resource.is_a?(ConsumerRole))
    end

    def envelope
      shop_market? ? Settings.notices.shop.partials.template : Settings.notices.individual.partials.template
    end

    def send_paper_notices?
      shop_market? ? Settings.notices.shop.store_paper_notice : Settings.notices.individual.store_paper_notice
    end

    def header
      shop_market? ? Settings.notices.shop.partials.header : Settings.notices.individual.partials.header
    end

    def footer
      shop_market? ? Settings.notices.shop.partials.footer : Settings.notices.individual.partials.footer
    end

    protected

    def execute_html_pdf_render
      @execute_html_pdf_render ||= self.to_html({kind: 'pdf'})
    end

    def recipient_target
      @recipient_target ||= begin
        if is_employer?
          resource.staff_roles.first
        elsif is_employee? || is_consumer?
          resource.person
        end
      end
    end
  end
end
