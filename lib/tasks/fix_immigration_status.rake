require 'csv'

namespace :consumer do
  desc "Fix Immigration Status"
  task fix_immigration_status: :environment do
    csv_file_path = "#{Rails.root}/#{ENV['csv_file_name']}"
    output_file_path = "#{Rails.root}/immigration_status_fix_result_for_#{ENV['csv_file_name']}"
    file = File.open(output_file_path, "w")
    CSV.foreach(csv_file_path, headers: true, :encoding => 'utf-8') do |row|
      person = Person.where(hbx_id: row.to_hash["policy.subscriber.person.hbx_id"]).first
      fix_citizen_status_overwritten_by_fedhub(person, file) if person.present?
    end
    file.close
  end
end

def fix_citizen_status_overwritten_by_fedhub(person, file)
  lpd_person =  person.try(:consumer_role).try(:lawful_presence_determination)
  file.puts "HBX ID, VERSION NUM., UPDATED_AT, CITIZEN_STATUS, CITIZENSHIP_RESULT, VLP_VERIFIED_AT"
  #Values for person record
  file.puts "#{person.hbx_id}, #{person.version}, #{person.updated_at}, #{lpd_person.try(:citizen_status)}, #{lpd_person.try(:citizenship_result)}, #{lpd_person.try(:vlp_verified_at)}, (*current version*)"
  
  # Values for all Versions of Person record.
  person.versions.reverse.each { |pv|
    lpd_version =  pv.try(:consumer_role).try(:lawful_presence_determination)
    file.puts "#{pv.hbx_id}, #{pv.version}, #{pv.updated_at}, #{lpd_version.try(:citizen_status)}, #{lpd_version.try(:citizenship_result)}, #{lpd_version.try(:vlp_verified_at)}"
  }
  # 1 The citizen_status values which have been received from the fed-hub prior to the addition of the field needs to be copied into citizenship_result.
  lpd_person.update_attributes!(citizenship_result: lpd_person.citizen_status) if lpd_person.present? && lpd_person.citizen_status.present? && lpd_person.citizenship_result.blank?

  # 2. Iterate over all versions of the Person instance (person->consumer_role->lawful_presence_determination) in a descending order (latest first)
    # 2a. When you get to a version that has 'vlp_verified_at' (LawfulPresenceDetermination) as blank, we know that is the version before Fedhub populated 'citizen_status' & 'vlp_verified_at'.
    #     We want to resotre citizen_status to the same value as that version.   
  person.versions.reverse.each do |pv|
    lpd_version = pv.try(:consumer_role).try(:lawful_presence_determination)
    if ( lpd_version.try(:citizen_status).present? && lpd_version.try(:vlp_verified_at).blank? && lpd_person.citizen_status != lpd_version.citizen_status) 
      person.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: lpd_version.citizen_status)
      file.puts "Copied citizen_status from [Version #{pv.version}] to [Version: #{person.version} (current Person record)]"
      break
    end
  end
  file.puts "*" * 140
end