class SbcProcessor2015
  S3_BUCKET = "sbc"

  def initialize(csv_path, sbc_dir_path)
    @csv_path = csv_path
    @sbc_dir_path = sbc_dir_path
    @sbc_file_paths = sbc_file_paths.compact
  end

  def pdf_path(sbc_file_name)
    @sbc_file_paths.detect do |file_path|
      sbc_file_name == File.basename(file_path)
    end
  end

  def sbc_file_paths
    Dir.glob("#{@sbc_dir_path}/**/*").map do |file_path|
      next if File.directory?(file_path)
      file_path
    end
  end

  def run
    counter = 0
    CSV.foreach(@csv_path, :headers => true) do |row|
      hios_id = row[0].gsub(/\A\p{Space}*|\p{Space}*\z/, '')

      # new model
      products = if hios_id.include? '-'
        ::BenefitMarkets::Products::Product.where(hios_id:hios_id)
      else
        ::BenefitMarkets::Products::Product.where(hios_id:/#{hios_id}/)
      end.select{|a| a.active_year.to_i  == row[2].strip.to_i}

      products.each do |product|
        file_name = row[1].strip

        if pdf_path(file_name).nil?
          puts "FILE NOT FOUND #{product.title} #{product.hios_id} #{file_name} "
          next
        end

        uri = if Rails.env.test?
          "urn:openhbx:terms:v1:file_storage:s3:bucket:mhc-enroll-sbc-test#11111111-1111-1111-1111-111111111111"
        else
          Aws::S3Storage.save(pdf_path(file_name), S3_BUCKET)
        end
        product.sbc_document = Document.new({title: file_name, subject: "SBC", format: 'application/pdf', identifier: uri})
        product.sbc_document.save!
        product.save!
        # end of new model

        # old model
        plan = Plan.where(active_year: product.active_year, hios_id: product.hios_id).first
        plan.update_attributes(sbc_document: product.sbc_document) if plan.present?
        # end old model

        counter += 1
        puts "Product #{product.title} #{product.hios_id}updated, SBC #{file_name}, Document uri #{product.sbc_document.identifier}" unless Rails.env.test?
      end
    end

    puts "Total #{counter} plans/products updated." unless Rails.env.test?

  end
end