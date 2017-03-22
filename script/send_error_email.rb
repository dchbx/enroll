  
  def secure_inbox_message(message_params, inbox_provider, folder)
    message = Message.new(message_params)
    message.folder =  Message::FOLDER_TYPES[folder]
    msg_box = inbox_provider.inbox
    msg_box.post_message(message)
    msg_box.save
  end

  def error_message(p, subject)
    body= File.open("#{Rails.root}/app/views/user_mailer/error_message_shop.html.erb").read
    from_provider = HbxProfile.current_hbx
    message_params = {
      sender_id: from_provider.try(:id),
      parent_message_id: p.id,
      from: from_provider.try(:legal_name),
      to: p.full_name,
      body: body,
      subject: subject
    }
    secure_inbox_message(message_params, p, :inbox)
  end

  file_name = "#{Rails.root}/bad_notices_list_1.csv"

  csv = CSV.open(file_name,"r",:headers =>true)  
  
  csv.each do |row|
    p = Person.where(:hbx_id => row["person.hbx_id"]).first
    subject = "2017 Final Insurance Enrollment Notice sent in error"
    error_message(p, subject)
  end
