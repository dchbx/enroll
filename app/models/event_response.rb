class EventResponse
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :lawful_presence_determination
  embedded_in :consumer_role

  field :received_at, type: DateTime
  field :body, type: String #the payload[:body] in the event response


  #vlp_response_parser
  def vlp_resp_to_hash
    Parsers::Xml::Cv::LawfulPresenceResponseParser.parse(this_vlp).to_hash
  end

  def parse_dhs
    return [vlp_resp_to_hash[:lawful_presence_indeterminate][:response_code].split("_").join(" "), "not lawfully present"] if vlp_resp_to_hash[:lawful_presence_indeterminate].present?
    return ["lawfully present", vlp_resp_to_hash[:lawful_presence_determination][:legal_status]] if vlp_resp_to_hash[:lawful_presence_determination].present? && vlp_resp_to_hash[:lawful_presence_determination][:response_code].eql?("lawfully_present")
    ["not lawfully present", "not lawfully present"] if vlp_resp_to_hash[:lawful_presence_determination].present? && vlp_resp_to_hash[:lawful_presence_determination][:response_code].eql?("not_lawfully_present")
  end

  def parse_ssa
    doc = Nokogiri::XML(self.body)
    ssn_node = doc.at_xpath("//ns1:ssn_verified", {:ns1 => "http://openhbx.org/api/terms/1.0"})
    return([false, false]) unless ssn_node
    ssn_valid = (ssn_node.content.downcase.strip == "true")
    return([false, false]) unless ssn_valid
    citizenship_node = doc.at_xpath("//ns1:citizenship_verified", {:ns1 => "http://openhbx.org/api/terms/1.0"})
    return([true, false]) unless citizenship_node
    citizenship_valid = citizenship_node.content.strip.downcase == "true"
    [true, citizenship_valid]
  end

  private

  def this_vlp
    Nokogiri::XML(body)
  end

end
