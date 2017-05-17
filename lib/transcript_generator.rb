class TranscriptGenerator

  attr_accessor :cv_path, :identifier

  # TRANSCRIPT_PATH = "#{Rails.root}/xml_files_10_27/ivl_policy_transcript_files/"
  # TRANSCRIPT_PATH = "#{Rails.root}/xml_files/shop_policies_transcript_files/"
  # TRANSCRIPT_PATH = "#{Rails.root}/individual_xmls_with_timestamps/ivl_transcript_batch/"
  TRANSCRIPT_PATH = "#{Rails.root}/person_transcripts"


  def initialize(market = 'individual')
    @identifier = 'hbx_id'
    @market = market
    my_logger
  end

  def my_logger
    @my_logger ||= Logger.new("#{Rails.root}/log/transcripts.log")
  end

  def execute
    create_directory(TRANSCRIPT_PATH)

    @count  = 0
    Dir.glob("#{Rails.root}/sample_xmls/*.xml").each do |file_path|
      begin
        @count += 1

        if @count % 100 == 0
          puts "------#{@count}"
        end

        individual_parser = Parsers::Xml::Cv::Importers::IndividualParser.new(File.read(file_path))
        # individual_parser = Parsers::Xml::Cv::Importers::EnrollmentParser.new(File.read(file_path))
        build_transcript(individual_parser.get_person_object)
        # build_transcript(individual_parser.get_enrollment_object)
      rescue Exception  => e
        my_logger.info("failed to process #{file_path}---#{e.to_s}")
      end
    end
  end

  def build_transcript(external_obj)
    transcript = Transcripts::PersonTranscript.new
    # transcript.shop = false
    transcript.find_or_build(external_obj)

    File.open("#{TRANSCRIPT_PATH}/#{@count}_#{transcript.transcript[:identifier]}_#{Time.now.to_i}.bin", 'wb') do |file|
      file.write Marshal.dump(transcript.transcript)
    end
  end

  def display_enrollment_transcripts
    count  = 0

    CSV.open("#{@market}_enrollment_change_sets_#{Time.now.strftime("%m_%d_%Y_%H_%M")}.csv", "w") do |csv|
      if @market == 'individual'
        csv << ['Enrollment HBX ID', 'Subscriber HBX ID','SSN', 'Last Name', 'First Name', 'HIOS_ID:PlanName', 'Other Effective On','Effective On', 'AASM State', 'Terminated On', 'Action', 'Section:Attribute', 'Value']
      else
        csv << ['Enrollment HBX ID', 'Subscriber HBX ID','SSN', 'Last Name', 'First Name', 'HIOS_ID:PlanName', 'Other Effective On','Effective On', 'AASM State', 'Terminated On', 'Employer FEIN', 'Employer Legalname', 'Action', 'Section:Attribute', 'Value']
      end

      starting = TimeKeeper.datetime_of_record.to_i
      # Dir.glob("#{TRANSCRIPT_PATH}/*.bin").each do |file_path|
      Dir.glob("#{Rails.root}/sample_xmls/*.xml").each do |file_path|

      # CSV.foreach("enrollments_edi_active_missing_in_EA.csv", headers: :true) do |row|
      #   file_path = "#{Rails.root}/LatestXmlFiles/ivl_final/#{row["Enrollment HBX ID"].strip}.xml"

        begin
          count += 1

          # rows = Transcripts::ComparisonResult.new(Marshal.load(File.open(file_path))).enrollment_csv_row

          individual_parser = Parsers::Xml::Cv::Importers::EnrollmentParser.new(File.read(file_path))
          other_enrollment = individual_parser.get_enrollment_object
          transcript = Transcripts::EnrollmentTranscript.new          
          transcript.shop = (@market == 'shop')
          transcript.find_or_build(other_enrollment)

          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript.transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = @market
          enrollment_transcript.process

          rows = enrollment_transcript.csv_row
          first_row = rows[0]

          if @market == 'individual'
            enrollment_removes = rows.select{|row| row[10] == 'remove' && row[11] == 'enrollment:hbx_id'}
            rows.reject!{|row| row[10] == 'update' && row[12].blank? && row[13].blank?}
            rows.reject!{|row| row[10] == 'remove' && row[11] == 'enrollment:hbx_id'}
          else
            enrollment_removes = rows.select{|row| row[11] == 'remove' && row[12] == 'enrollment:hbx_id'}
            rows.reject!{|row| row[12] == 'update' && row[14].blank?}
            rows.reject!{|row| row[12] == 'remove' && row[13] == 'enrollment:hbx_id'}
          end

          if rows.empty?
            if @market == 'individual'
              csv << (first_row[0..9] + ['match', 'match:enrollment'] + [''] + enrollment_transcript.updates['match:enrollment'].to_a)
            else
              csv << (first_row[0..11] + ['match', 'match:enrollment'])
            end
            enrollment_removes.each{|row| csv << row}
          else
            rows.each{|row| csv << row}
            enrollment_removes.each{|row| csv << row}
          end

          if count % 100 == 0
            ending = TimeKeeper.datetime_of_record.to_i
            puts "processed #{count}--time lapse #{ending - starting}"
            starting = TimeKeeper.datetime_of_record.to_i
          end
        rescue Exception => e
          puts "Failed.....#{file_path}--#{e.inspect}"
        end
      end
    end
  end

  def display_family_transcripts
    count  = 0

    CSV.open('family_change_sets.csv', "w") do |csv|
      csv << ['Subscriber HBX ID', 'SSN', 'Last Name', 'First Name', 'Action', 'Section:Attribute', 'Value', 'Action Taken']

      # Dir.glob("#{TRANSCRIPT_PATH}/*.bin").each do |file_path|
      Dir.glob("#{Rails.root}/xml_files_10_27/ivl_family_xmls/*.xml").each do |file_path|
        begin
          count += 1
          # rows = Transcripts::ComparisonResult.new(Marshal.load(File.open(file_path))).family_csv_row

          individual_parser = Parsers::Xml::Cv::Importers::FamilyParser.new(File.read(file_path))
          other_family = individual_parser.get_family_object
          transcript = Transcripts::FamilyTranscript.new
          transcript.find_or_build(other_family)

          family_importer = Importers::Transcripts::FamilyTranscript.new
          family_importer.transcript = transcript.transcript
          family_importer.market = @market
          family_importer.other_family = other_family
          family_importer.process

          rows = family_importer.csv_row

          next unless rows.present?

          first_row = rows[0]
          rows.reject!{|row| row[4] == 'update' && row[6].blank?}

          if rows.empty?
            csv << (first_row[0..3] + ['match', 'match:family'])
          else
            rows.each{|row| csv << row}
          end

          if count % 100 == 0
            puts "processed #{count}"
          end
        rescue Exception => e
          puts "Failed.....#{file_path}"
        end
      end
    end
  end

  def display_transcripts
    count  = 0

    CSV.open('person_change_sets.csv', "w") do |csv|
      csv << ['HBX ID', 'SSN', 'Last Name', 'First Name', 'Action', 'Section:Attribute', 'Value', 'Action Taken']

      Dir.glob("#{TRANSCRIPT_PATH}/*.bin").each do |file_path|
        begin
          count += 1

          # rows = Transcripts::ComparisonResult.new(Marshal.load(File.open(file_path))).csv_row

          person_importer = Importers::Transcripts::PersonTranscript.new
          person_importer.transcript = Marshal.load(File.open(file_path))
          person_importer.market = @market
          person_importer.process

          rows = person_importer.csv_row

          first_row = rows[0]
          rows.reject!{|row| row[4] == 'update' && row[6].blank?}

          if rows.empty?
            csv << (first_row[0..3] + ['match', 'match:ssn', ''] + ['Matched'])
          else
            rows.each{|row| csv << row}
          end

          if count % 100 == 0
            puts "processed #{count}"
          end
        rescue Exception => e
          puts "Failed.....#{file_path}"
        end
      end
    end
  end

  private

  def create_directory(path)
    if Dir.exists?(path)
      FileUtils.rm_rf(path)
    end
    Dir.mkdir path
  end
end
