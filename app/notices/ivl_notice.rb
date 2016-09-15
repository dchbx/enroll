class IvlNotice < Notice

  Required= Notice::Required + []

  def initialize(options ={})
    super
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page
    attach_dchl_rights
    prepend_envelope
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def prepend_envelope
    envelope = Envelope.new
    envelope.fill_envelope(notice, mpi_indicator)
    envelope.render_file(envelope_path)
    join_pdfs [envelope_path, notice_path]
  end

  def attach_dchl_rights
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'dchl_rights.pdf')]
  end

  def attach_blank_page
    blank_page = Rails.root.join('lib/pdf_templates', 'blank.pdf')

    page_count = Prawn::Document.new(:template => notice_path).page_count
    if (page_count % 2) == 1
      join_pdfs [notice_path, blank_page]
    end
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