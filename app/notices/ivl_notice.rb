class IvlNotice < Notice

  include ActionView::Helpers::NumberHelper

  Required= Notice::Required + []

  def initialize(options ={})
    super
  end

  def deliver
    append_hbe
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_appeals
    attach_non_discrimination
    attach_taglines
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def attach_required_documents
    generate_custom_notice('notices/ivl/documents_section')
    attach_blank_page(custom_notice_path)
    join_pdfs [notice_path, custom_notice_path]
    clear_tmp
  end

  def generate_custom_notice(custom_template)
    File.open(custom_notice_path, 'wb') do |file|
      file << self.pdf_custom(custom_template)
    end
  end

  def pdf_custom(custom_template)
    WickedPdf.new.pdf_from_string(self.html({kind: 'pdf', custom_template: custom_template}), pdf_options_custom)
  end

  def pdf_options_custom
    options = {
      margin:  {
        top: 15,
        bottom: 20,
        left: 22,
        right: 22
      },
      disable_smart_shrinking: true,
      dpi: 96,
      page_size: 'Letter',
      formats: :html,
      encoding: 'utf8',
      header: {
        content: ApplicationController.new.render_to_string({
          template: 'notices/shared/header_for_documents.html.erb',
          layout: false,
          locals: { recipient: recipient, notice: notice}
          }),
        }
    }
    options.merge!({footer: {
      content: ApplicationController.new.render_to_string({
        template: "notices/shared/footer_ivl.html.erb",
        layout: false,
        locals: {notice: notice}
      })
    }})
    options
  end

  def clear_tmp
    File.delete(custom_notice_path)
  end

  def custom_notice_path
    Rails.root.join("tmp", "documents_section_#{notice_filename}.pdf")
  end

  def generate_custom_notice(custom_template)
    File.open(custom_notice_path, 'wb') do |file|
      file << self.pdf_custom(custom_template)
    end
  end

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
      url: Settings.site.home_url,
      phone: phone_number_format(Settings.contact_center.phone_number),
      email: Settings.contact_center.email_address,
      short_url: "#{Settings.site.short_name.gsub(/[^0-9a-z]/i,'').downcase}.com",
    })
  end

  def phone_number_format(number)
    number_to_phone(number.gsub(/^./, "").gsub('-',''), area_code: true)
  end

  def attach_dchl_rights
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'dchl_rights.pdf')]
  end

  def attach_voter_application
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'voter_application.pdf')]
  end

  def attach_taglines
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'taglines.pdf')]
  end

  def attach_appeals
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ivl_appeal_rights.pdf')]
  end

  def attach_non_discrimination
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ivl_non_discrimination.pdf')]
  end
  
  def join_pdfs_with_path(pdfs, path = nil)
    pdf = File.exists?(pdfs[0]) ? CombinePDF.load(pdfs[0]) : CombinePDF.new
    pdf << CombinePDF.load(pdfs[1])
    path_to_save = path.nil? ? notice_path : path
    pdf.save path_to_save
  end

  def attach_blank_page(template_path = nil)
    path = template_path.nil? ? notice_path : template_path
    blank_page = Rails.root.join('lib/pdf_templates', 'blank.pdf')
    page_count = Prawn::Document.new(:template => path).page_count
    if (page_count % 2) == 1
      join_pdfs_with_path([path, blank_page], path)
    end
  end

  def lawful_presence_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('Citizenship') || person.consumer_role.outstanding_verification_types.include?('Immigration status')
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: capitalize_quadrant(primary_address.address_1.to_s.titleize),
      street_2: capitalize_quadrant(primary_address.address_2.to_s.titleize),
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def check(value)
    (value.try(:upcase) == "YES") ? true : false
  end

  def capitalize_quadrant(address_line)
    address_line.split(/\s/).map do |x|
      x.strip.match(/^NW$|^NE$|^SE$|^SW$/i).present? ? x.strip.upcase : x.strip
    end.join(' ')
  end

  # def join_pdfs(pdfs)
  #   Prawn::Document.generate(notice_path, {:page_size => 'LETTER', :skip_page_creation => true}) do |pdf|
  #     pdfs.each do |pdf_file|
  #       if File.exists?(pdf_file)
  #         pdf_temp_nb_pages = Prawn::Document.new(:template => pdf_file).page_count

  #         (1..pdf_temp_nb_pages).each do |i|
  #           pdf.start_new_page(:template => pdf_file, :template_page => i)
  #         end
  #       end
  #     end
  #   end
  # end
end