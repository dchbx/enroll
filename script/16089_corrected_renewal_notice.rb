require 'csv'

file_name = "#{Rails.root}/corrected_renewal_notice_list.csv"
csv = CSV.open(file_name,"r",:headers =>true, :encoding => 'ISO-8859-1')
data = csv.to_a

data.each do |row|
  org = Organization.where(:fein => row["EIN"]).first
  if org.present?
    begin
      if (org.employer_profile.inbox.messages.where(:subject => "Group Renewal Available").first.present? || org.employer_profile.documents.where(:title => "GroupRenewalAvailable").first.present?)
        event = "group_renewal_5"
        event_kind = ApplicationEventKind.where(:event_name => event).first
        notice_trigger = event_kind.notice_triggers.first
        builder = notice_trigger.notice_builder.camelize.constantize.new(org.employer_profile, {
                  template: notice_trigger.notice_template,
                  subject: event_kind.title,
                  key: "corrected",
                  mpi_indicator: notice_trigger.mpi_indicator,
                  }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
        puts "Delivered notice to #{org.legal_name}" unless Rails.env.test?
      else
        puts "No notice present for #{org.legal_name}" unless Rails.env.test?
      end
    rescue Exception => e
      puts "Unable to send group_renewal_5 notice to #{org.legal_name} due to #{e}" unless Rails.env.test?
    end
  else
    puts "No Organization found with the given FEIN - #{row["EIN"]}" unless Rails.env.test?
  end
end
