controller = Events::EmployersController.new
PropertiesSlug = Struct.new(:reply_to, :headers)

ConnectionSlug = Struct.new(:employer_fein) do
  def create_channel
    self
  end

  def default_exchange
    self
  end

  def close
  end

  def publish(payload, headers)
    File.open(File.join("employer_xmls", "#{employer_fein}.xml"), 'w') do |f|
      f.puts payload
    end
  end
end

feins = %w(
)

feins.each do |fein|
  org = Organization.where(:fein => fein.gsub("-","")).first
  e_id = org.hbx_id
  properties_slug = PropertiesSlug.new("", {:employer_id => e_id, manual_gen: true})
  controller.resource(ConnectionSlug.new(e_id), "", properties_slug, "")
end
