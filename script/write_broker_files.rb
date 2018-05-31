controller = Events::BrokersController.new
PropertiesSlug = Struct.new(:reply_to, :headers)

ConnectionSlug = Struct.new(:broker_npn) do
  def create_channel
    self
  end

  def default_exchange
    self
  end

  def close
  end

  def publish(payload, headers)
    Dir.mkdir("broker_xmls") unless File.exists?("broker_xmls")
    File.open(File.join("broker_xmls", "#{broker_npn}.xml"), 'w') do |f|
      f.puts payload
    end
  end
end

npn_list = Person.where("broker_role.aasm_state" => "active").map do |pers|
  pers.broker_role.npn
end

npn_list.each do |npn|
  properties_slug = PropertiesSlug.new("", {:broker_id => npn})
  controller.resource(ConnectionSlug.new(npn), "", properties_slug, "")
end

