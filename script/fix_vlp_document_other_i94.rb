# frozen_string_literal: true

require 'csv'
field_names = %w[First_Name Last_Name Hbx_ID consumer_role_aasm_state vlp_doc_id]
file_name = "#{Rails.root}/other_i94_vlp_issue_people_with_consumer_aasm_state.csv"
CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names
  Person.all.where(:'consumer_role.vlp_documents.subject' => 'Other (With I-94)').each do |person|
    vlp_docs = person.consumer_role.vlp_documents.where(subject: 'Other (With I-94)')
    next person if vlp_docs.blank?
    vlp_docs.each do |vlp_doc|
      vlp_doc.update_attributes!(subject: 'Other (With I-94 Number)')
      csv << [person.first_name, person.last_name, person.hbx_id, person.consumer_role.aasm_state, vlp_doc.id]
    end
  rescue StandardError => e
    puts e.message
  end
end
