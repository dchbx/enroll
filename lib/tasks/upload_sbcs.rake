require 'csv'
require Rails.root.join("lib", "sbc", "sbc_processor")
require Rails.root.join("lib", "sbc", "sbc_processor2015")

ENV_LIST = ['qa', 'prod', 'preprod', 'cte', 'cpr', 'uat']

namespace :sbc do
  #USAGE rake sbc:upload['MASTER 2016 QHP_QDP IVAL & SHOP Plan and Rate Matrix v.9.xlsx','v.2 SBCs 9.22.2015']
  task :upload, [:matrix_path, :dir_path] => :environment do |task, args|
    sbc_processor = SbcProcessor.new(args.matrix_path, args.dir_path)
    sbc_processor.run
  end

  # USAGE rake sbc:export
  # This will export a map of plan and sbc pdfs in S3 to plans-sbcs.csv
  # A CSV with plan.id, plan.hios_id, plan.active_year, plan.sbc_document.identifier, plan.sbc_document.title
  task :export => :environment do
    counter = 0
    file_path = "plans-sbcs.csv"
    plans = Plan.all
    csv = CSV.open(file_path, "w") do |csv|
      plans.each do |plan|
        next unless plan.sbc_document
        next unless plan.sbc_document.identifier
        csv << [plan.name, plan.hios_id, plan.active_year, plan.sbc_document.identifier.split('#').last, plan.sbc_document.title]
        counter += 1
      end
    end
    puts "Total #{counter} plans exported"
    puts "CSV written #{file_path} with schema plan.name, plan.hios_id, plan.active_year, plan.sbc_document.identifier key, plan.sbc_document.title"
  end

  # USAGE rake sbc:export
  # Seeds the SBC documents in Plans. SBCs are already uploaded to S3 before this runs.
  # Should run while seeding.
  task :map => :environment do

    Plan.all.each do |plan|
      plan.sbc_document = nil
    end

    file_path = Rails.root.join("db", "seedfiles", "plans-sbcs.csv").to_s
    aws_env = ENV['AWS_ENV'] || 'local'
    CSV.foreach(file_path) do |row|
      next if (row[1].include? "-") && (!row[1].include? "-01")
      plan_find_regex = Regexp.compile("^" + row[1].to_s.split("-").first)
      Plan.where(hios_id: plan_find_regex, active_year: row[2]).each do |plan|
        bucket_name = "#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}"
        uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}##{row[3]}"
        plan.sbc_document = Document.new({title: row[4], subject: "SBC", format: 'application/pdf', identifier: uri})
        plan.sbc_document.save!
        plan.save!
      end
    end

    CSV.foreach(file_path) do |row|
      next unless row[1].include? "-"
      plan = Plan.where(hios_id: row[1], active_year: row[2]).first
      next if plan.nil?
      bucket_name = "#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}"
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}##{row[3]}"
      plan.sbc_document = Document.new({title: row[4], subject: "SBC", format: 'application/pdf', identifier: uri})
      plan.sbc_document.save!
      plan.save!
    end

    puts "#{Plan.all.select do |p|
      p.sbc_document.present?
    end.count} plans updated with sbc document"
  end

  namespace :'2015' do
    #USAGE rake sbc:2015:upload['2015.csv','2015pdfs']
    task :upload, [:csv_path, :dir_path] => :environment do |task, args|
      sbc_processor = SbcProcessor2015.new(args.csv_path, args.dir_path)
      sbc_processor.run
    end
  end
end