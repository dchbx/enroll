feins = [] #Organization.where(:"employer_profile".exists=>true).map(&:fein)

Dir.mkdir("employer_xmls.v2") unless File.exists?("employer_xmls.v2")

carrier_abbreviations = {
    "CareFirst":"AHI", "Aetna":"GHMSI", "Kaiser":"KFMASI", "United Health Care": "UHIC", "Delta Dental":"DDPA",
  "Dentegra":"DTGA", "Dominion":"DMND", "Guardian":"GARD", "BestLife":"BLHI", "MetLife":"META"}

plan_year = { "start_date":"", "end_date":"" }

XML_NS = "http://openhbx.org/api/terms/1.0"

def write(payload, file_name)
  File.open(File.join("employer_xmls.v2", "#{file_name}.xml"), 'w') do |f|
    f.puts payload
  end
end

def remove_other_carrier_nodes(xml, trading_partner, p_pye, pys)
  doc = Nokogiri::XML(xml)
  doc.xpath("//cv:elected_plans/cv:elected_plan", {:cv => XML_NS}).each do |node|
    carrier_name = node.at_xpath("cv:carrier/cv:name", {:cv => XML_NS}).content
    if carrier_name.to_s.strip.downcase != trading_partner.downcase.strip
      node.remove
    end
  end

  doc.xpath("//cv:benefit_group/cv:elected_plans[not(cv:elected_plan)]", {:cv => XML_NS}).each do |node|
    node.remove
  end
  doc.xpath("//cv:benefit_group[not(cv:elected_plans)]", {:cv => XML_NS}).each do |node|
    node.remove
  end
  doc.xpath("//cv:plan_year/cv:benefit_groups[not(cv:benefit_group)]", {:cv => XML_NS}).each do |node|
    node.remove
  end
  doc.xpath("//cv:plan_year[not(cv:benefit_groups)]", {:cv => XML_NS}).each do |node|
    node.remove
  end
  employer_id = doc.at_xpath("//cv:organization/cv:id/cv:id", {:cv => XML_NS}).content
  has_last_year = false
  has_this_year = false
  event = "ignore"
  if doc.xpath("//cv:plan_year/cv:plan_year_end[contains(text(), '#{p_pye}')]", {:cv => XML_NS}).any?
    has_last_year = true
  end
  if doc.xpath("//cv:plan_year/cv:plan_year_start[contains(text(), '#{pys}')]", {:cv => XML_NS}).any?
    has_this_year = true
  end
  if has_last_year
    if has_this_year
      event = "urn:openhbx:events:v1:employer#benefit_coverage_renewal_open_enrollment_ended"
    else
      event = "urn:openhbx:events:v1:employer#benefit_coverage_period_expired"
    end
  else
    if has_this_year
      event = "urn:openhbx:events:v1:employer#benefit_coverage_initial_binder_paid"
    end
  end
  [event, employer_id, doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)]
end

# return end_date of previous active plan year
def previous_plan_year_end_date(employer_profile)
  #sort by increasing plan year start_on and return the previous active plan year at index -2
  previous_plan_year = employer_profile.plan_years.select(&:eligible_for_export?).sort_by do |plan_year|
    plan_year.start_on
  end[-2]

  if previous_plan_year
    previous_plan_year.end_on.strftime("%Y%m%d")
  else
    "19700101" # an invalid date which will not match any date on xml
  end
end

views = Rails::Application::Configuration.new(Rails.root).paths["app/views"]
views_helper = ActionView::Base.new views
include EventsHelper

organizations_hash = {} # key is carrier name, value is the return object of remove_other_carrier_nodes()

#for each employer (fein)
# 1 find the list of carriers in plan years
# 2 generate the organization cv2
# 3 using remove_other_carrier_nodes, remove the carrier plans of carriers other then 'carrier'
# create a hash with key as carrier and value as array [organization_xml, carrier, plan year end date, plan year start date]
feins.each do |fein|

  begin
    employer_profile = Organization.where(:fein => fein.gsub("-", "")).first.employer_profile

    carriers = employer_profile.plan_years.select(&:eligible_for_export?).select do |py|
      py.start_on == Date.parse(plan_year[:start_date])
    end.flat_map(&:benefit_groups).flat_map(&:elected_plans).flat_map(&:carrier_profile).uniq! || []

    previous_plan_year = employer_profile.plan_years.select(&:eligible_for_export?).sort_by do |plan_year|

    end

    carriers.each do |carrier|
      #puts "Processing fein #{fein} for #{carrier.legal_name}"
      cv_xml = views_helper.render file: File.join(Rails.root, "/app/views/events/v2/employers/updated.xml.haml"), :locals => {employer: employer_profile}

      organizations_hash[carrier.legal_name] = [] if organizations_hash[carrier.legal_name].nil?
      organizations_hash[carrier.legal_name] << remove_other_carrier_nodes(cv_xml, carrier.legal_name,
                                                                           previous_plan_year_end_date(employer_profile),
                                                                           plan_year[:start_date])
    end
  rescue => e
      puts "Error FEIN #{fein} " + e.message
  end
end

# iterate the hash and generate group xml v2 for each carrier, including all employers for that carrier
organizations_hash.each do |carrier, organizations|
  xml = views_helper.render file: File.join(Rails.root, "/app/views/events/v2/employers/group_xml.haml"),
                            :locals => {carrier:nil, organizations:organizations, abbreviation:carrier_abbreviations[carrier.to_sym], plan_year:plan_year}
  write(xml, carrier)
end