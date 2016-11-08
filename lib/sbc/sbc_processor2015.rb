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

      if hios_id.include? '-'
        plans = Plan.where(active_year:'2017').and(hios_id:hios_id)
      else
        plans = Plan.where(active_year:'2017').and(hios_id:/#{hios_id}/)
      end

      plans.each do |plan|
        file_name = row[1].strip

        if pdf_path(file_name).nil?
          puts "FILE NOT FOUND #{plan.name} #{plan.hios_id} #{file_name} "
          next
        end

        uri = Aws::S3Storage.save(pdf_path(file_name), S3_BUCKET)
        plan.sbc_document = Document.new({title: file_name, subject: "SBC", format: 'application/pdf', identifier: uri})
        plan.sbc_document.save!
        plan.save!
        counter += 1
        puts "Plan #{plan.name} #{plan.hios_id}updated, SBC #{file_name}, Document uri #{plan.sbc_document.identifier}"
      end
    end
    puts "Total #{counter} plans updated."
  end
end