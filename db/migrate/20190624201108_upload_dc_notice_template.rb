# frozen_string_literal: true

class UploadDcNoticeTemplate < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"

      @logger = Logger.new("#{Rails.root}/log/dc_notice_template_migration.log") unless Rails.env.test?
      @logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      remove_existing_notice
      upload_notice

      @logger.info "End of the script- #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down; end

  private

  def self.remove_existing_notice
    say_with_time("Time taken to remove existing notices") do
      Notifier::NoticeKind.all.delete_all
    end
  end

  def self.upload_notice
    say_with_time("Time taken to remove existing notices") do
      begin
        @errors = []
        file = File.join("db", "notice_template.csv")
        notices = Roo::Spreadsheet.open(file)
        notices.each do |notice_row|
          next if notice_row[1] == 'Notice Number'

          if Notifier::NoticeKind.where(notice_number: notice_row[1]).blank?
            notice = Notifier::NoticeKind.new(market_kind: notice_row[0], notice_number: notice_row[1], title: notice_row[2], description: notice_row[3], recipient: notice_row[4], event_name: notice_row[5])
            notice.template = Notifier::Template.new(raw_body: notice_row[6])
            @errors << "Notice #{notice_row[1]} got errors: #{notice.errors}" unless notice.save
          else
            @errors << "Notice #{notice_row[1]} already exists."
          end
        end
      rescue Exception => e
        print 'F' unless Rails.env.test?
        @logger.error " Notice Template error: #{e.inspect}" unless Rails.env.test?
      end
      puts "Errors: #{@errors}"
      puts "Total Notice Template uploaded: #{Notifier::NoticeKind.all.count}"
    end
  end

end