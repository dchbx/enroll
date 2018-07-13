# This class generates v2 xmls
#
# Inputs
# 1 Array of FEINS
# 2 plan_year[:start_date] e.g. 20160901
# 3 plan_year[:end_date] e.g. 20160831
#
# Output
# Xml files written to Rails.root/employer_xmls.v2/
#
# Usage
# v2_group_xml_generator =  V2GroupXmlGenerator.new(feins, start_date, end_date)
# v2_group_xml_generator.generate_xmls
class V2GroupXmlGenerator

  XML_NS = "http://openhbx.org/api/terms/1.0"

  CARRIER_ABBREVIATIONS = {
      "CareFirst": "GHMSI", "Aetna": "AHI", "Kaiser": "KFMASI", "UnitedHealthCare": "UHIC", "Delta Dental": "DDPA",
      "Dentegra": "DTGA", "Dominion": "DMND", "Guardian": "GARD", "BestLife": "BLHI", "MetLife": "META", "Health New England, Inc.": "HNE", "Boston Medical Center HealthNet Plan": "BMCHP", "Fallon Community Health Plan, Inc.": "FCHP",
      "Minuteman Health, Inc.": "MHI"}

  # Inputs
  # 1 Array of FEINS
  # 2 plan_year[:start_date] e.g. 20160901
  # 3 plan_year[:end_date] e.g. 20160831
  def initialize(feins, plan_year_start, plan_year_end)
    @feins = feins
    Dir.mkdir("employer_xmls.v2") unless File.exists?("employer_xmls.v2") #Output directory
    @plan_year = {"start_date": plan_year_start, "end_date": plan_year_end}
  end

  def generate_xmls
    views = Rails::Application::Configuration.new(Rails.root).paths["app/views"]
    views_helper = ActionView::Base.new views
    views_helper.class.send(:include, EventsHelper)
    views_helper.class.send(:include, Config::AcaHelper)

    organizations_hash = {} # key is carrier name, value is the return object of remove_other_carrier_nodes()

#for each employer (fein)
# 1 find the list of carriers in plan years
# 2 generate the organization cv
# 3 using remove_other_carrier_nodes, remove the carrier plans of carriers other then 'carrier'
# create a hash with key as carrier and value as array [organization_xml, carrier, plan year end date, plan year start date]
# 4 if carrier-switch then generate xml for each of the dropped carrier and add to hash.
    @feins.uniq.each do |fein|

      begin
        employer_profile = BenefitSponsors::Organizations::Organization.where(:fein => fein.gsub("-", "")).first.employer_profile
        benefit_application = find_benefit_application(employer_profile)

        unless benefit_application.present?
          puts "benefit_application not found"
          return
        end

        carrier_profiles = benefit_application_carriers(benefit_application).flatten.uniq
        next if carrier_profiles.length == 0

        cv_xml = nil
        carrier_profiles.each do |carrier|
          cv_xml = views_helper.render file: File.join(Rails.root, "/app/views/events/v2/employers/updated.xml.haml"), :locals => {employer: employer_profile, manual_gen: true}

          organizations_hash[carrier.legal_name] = [] if organizations_hash[carrier.legal_name].nil?

          organizations_hash[carrier.legal_name] << remove_other_carrier_nodes(cv_xml, carrier.legal_name,
                                                                               employer_profile, benefit_application)
        end

        # carrier switch scenario
        switched_carriers(employer_profile, benefit_application).uniq.each do |switched_carrier|
          organizations_hash[switched_carrier.legal_name] = [] if organizations_hash[switched_carrier.legal_name].nil?
          organizations_hash[switched_carrier.legal_name] << remove_other_carrier_nodes(cv_xml, switched_carrier.legal_name,
                                                                                        employer_profile,
                                                                                        predecessor_application(benefit_application).effective_period.min.strftime("%Y%m%d"),
                                                                                        {event: "urn:openhbx:events:v1:employer#benefit_coverage_renewal_carrier_dropped"})
        end
      rescue => e
        puts "Error FEIN #{fein} #{e.message}\n " + e.backtrace.to_s
      end
    end

# iterate the hash and generate group xml v2 for each carrier, including all employers for that carrier
    organizations_hash.each do |carrier, organizations|
      xml = views_helper.render file: File.join(Rails.root, "/app/views/events/v2/employers/group_xml.haml"),
                                :locals => {carrier: nil, organizations: organizations, abbreviation: CARRIER_ABBREVIATIONS[carrier.to_sym], plan_year: @plan_year}
      write(xml, carrier)
    end
  end

  private
  def write(payload, file_name)
    File.open(File.join("employer_xmls.v2", "#{file_name}.xml"), 'w') do |f|
      f.puts payload
    end
  end

  def remove_other_carrier_nodes(xml, trading_partner, employer_profile, benefit_application, options = {})
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
    event = "urn:openhbx:events:v1:employer#other"

    previous_plan_year_value = predecessor_application(benefit_application)

    if previous_plan_year_value.present?
      has_last_year = true
    end

    if doc.xpath("//cv:plan_year/cv:plan_year_start[contains(text(), '#{@plan_year[:start_date]}')]", {:cv => XML_NS}).any?
      has_this_year = true
    end

    # carrier switch case
    # the is the xml for the dropped carrier
    if (options[:event].present?) && (options[:event] == "urn:openhbx:events:v1:employer#benefit_coverage_renewal_carrier_dropped")
      return [options[:event], employer_id, doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)]
    end

    if has_last_year && has_this_year
      if employer_profile.active_benefit_sponsorship.is_eligible?
        event = "urn:openhbx:events:v1:employer#benefit_coverage_renewal_application_eligible"
      elsif employer_profile.active_benefit_sponsorship.terminated? && employer_profile.active_benefit_sponsorship.termination_kind == :voluntary
        event = "urn:openhbx:events:v1:employer#benefit_coverage_period_terminated_voluntary"
      elsif employer_profile.active_benefit_sponsorship.terminated? && employer_profile.active_benefit_sponsorship.termination_kind == :involuntary
        event = "urn:openhbx:events:v1:employer#benefit_coverage_period_terminated_nonpayment"
      end
    elsif has_this_year
      if employer_profile.active_benefit_sponsorship.is_eligible?
        event = "urn:openhbx:events:v1:employer#benefit_coverage_initial_application_eligible"
      elsif employer_profile.active_benefit_sponsorship.terminated? && employer_profile.active_benefit_sponsorship.termination_kind == :voluntary
        event = "urn:openhbx:events:v1:employer#benefit_coverage_period_terminated_voluntary"
      elsif employer_profile.active_benefit_sponsorship.terminated? && employer_profile.active_benefit_sponsorship.termination_kind == :involuntary
        event = "urn:openhbx:events:v1:employer#benefit_coverage_period_terminated_nonpayment"
      end
    end

    [event, employer_id, doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)]
  end

# return previous active plan year
  def predecessor_application(benefit_application)
    benefit_application.predecessor_application
  end

  def benefit_application_carriers(benefit_application)
    carrier_profiles = []
    benefit_application.benefit_packages.each do |benefit_package|
      carrier_profiles << benefit_package.health_sponsored_benefit.products(benefit_package.effective_period.min).map(&:issuer_profile).uniq
      carrier_profiles << benefit_package.dental_sponsored_benefit.products(benefit_package.effective_period.min).map(&:issuer_profile).uniq if benefit_package.dental_sponsored_benefit.present?
    end
    carrier_profiles
  end

#returns an array of carriers which were switched from and need to be informed
  def switched_carriers(employer_profile, benefit_application)
    previous_plan_year_value = predecessor_application(benefit_application)
    return [] if previous_plan_year_value.nil? #no previous plan year
    this_plan_year = find_benefit_application(employer_profile)
    this_plan_year_carrier_profiles = benefit_application_carriers(this_plan_year).flatten.uniq
    previous_plan_year_carrier_profiles =  benefit_application_carriers(previous_plan_year_value).flatten.uniq
    previous_plan_year_carrier_profiles - this_plan_year_carrier_profiles
  end

  def find_benefit_application(employer_profile)
    benefit_application = employer_profile.benefit_applications.select {|benefit_application|  benefit_application.effective_period.min == Date.parse(@plan_year[:start_date]) && (benefit_application.enrollment_open? || benefit_application.enrollment_closed? || benefit_application.eligible_for_export?)}
    benefit_application.present? ? benefit_application.first : nil
  end
end


#v2_group_xml_generator =  V2GroupXmlGenerator.new(['521748601'], '20161101', '20171031')
#v2_group_xml_generator.generate_xmls

