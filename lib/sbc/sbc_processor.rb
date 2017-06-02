require 'ostruct'
class SbcProcessor

  SHEETS = ['IVL', 'SHOP Q1', 'SHOP Q2', 'SHOP Q3', 'SHOP Q4']
  CARRIERS = ["Dominion", "Aetna", "CareFirst", "Delta Dental", "Dentegra", "MetLife", "Kaiser", "UnitedHealthcare"]
  S3_BUCKET = "sbc"

  def initialize(matrix_path, sbc_dir_path)
    @matrix_path = matrix_path
    @sbc_dir_path = sbc_dir_path
    @sbc_hash = {}
    @sbc_file_paths = sbc_file_paths.compact
  end

  def run
    begin
      read_matrix
      upload
    rescue Exception => e
      puts "ERROR : #{e.message}"
    end

  end

  def upload
    counter = 0
    @sbc_hash.each do |plan_name, data|
      plan = Plan.where(active_year: '2016').and(name: plan_name.gsub(/\A\p{Space}*|\p{Space}*\z/, '')).first
      if plan.nil?
        puts "PLAN NOT FOUND year 2016 plan #{plan_name}"
        next
      end
      uri = Aws::S3Storage.save(pdf_path(data.sbc_file_name), S3_BUCKET)
      if uri.nil?
        uri = Aws::S3Storage.save(pdf_path(data.sbc_file_name.gsub(' ','')), S3_BUCKET)
      end

      if uri.nil?
        puts "URI nil #{plan.name} #{plan.hios_id} #{data.sbc_file_name}"
        next
      end
      plan.sbc_document = Document.new({title: data.sbc_file_name, subject: "SBC", format: 'application/pdf', identifier: uri})
      plan.sbc_document.save!
      plan.save!
      counter += 1
      plan = Plan.where(active_year: '2016').and(name: plan_name.gsub(/\A\p{Space}*|\p{Space}*\z/, '')).first
      puts "Plan #{plan.name} updated, SBC #{data.sbc_file_name}, Document uri #{plan.sbc_document.identifier}"
    end
    puts "Total #{counter} plans updated."
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

  def read_matrix
    xls = Roo::Spreadsheet.open(@matrix_path)
    SHEETS.each do |sheet_name|
      last_row = xls.sheet(sheet_name).last_row
      (2..last_row).each do |i|
        row = xls.sheet(sheet_name).row(i)
        @sbc_hash[row[3]] = OpenStruct.new(:carrier => sbc_hash_key(row[0]), :sbc_file_name => row[7])
      end
    end
  end

  # key could be carrier name (CareFirst) or a variation of it (CareFirst/OPM)
  def sbc_hash_key(carrier_name)
    return carrier_name if CARRIERS.include?(carrier_name)
    return CARRIERS.each.detect do |k|
      (carrier_name.include? k) || (k.include? carrier_name)
    end
  end
end