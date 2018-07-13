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
    Dir.mkdir("employer_xmls") unless File.exists?("employer_xmls")
    File.open(File.join("employer_xmls", "#{employer_fein}.xml"), 'w') do |f|
      f.puts payload
    end
  end
end

# feins = %w(
# )

feins = [ARGV[0]]

feins.each do |fein|
  org = BenefitSponsors::Organizations::Organization.where(:fein => fein).first
  # org = BenefitSponsors::Organizations::Organization.where(:fein => fein.gsub("-","")).first
  e_id = org.hbx_id
  properties_slug = PropertiesSlug.new("", {:employer_id => e_id, manual_gen: true})
  controller.resource(ConnectionSlug.new(e_id), "", properties_slug, "")
end
