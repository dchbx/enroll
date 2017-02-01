controller = Events::PoliciesController.new

PropertiesSlug = Struct.new(:reply_to, :headers)

ConnectionSlug = Struct.new(:policy_id) do
  def create_channel
    self
  end

  def default_exchange
    self
  end

  def close
  end

  def publish(payload, properties)
    if properties[:headers][:return_status] == "200"
      File.open(File.join("policy_cvs", "#{policy_id}.xml"), 'w') do |f|
        f.puts payload
      end
    else
      File.open(File.join("policy_cvs", "#ERROR_#{policy_id}.xml"), 'w') do |f|
        f.puts payload
      end
    end
  end
end

qs = Queries::PolicyAggregationPipeline.new

filter_date = (Time.now.utc.beginning_of_day)-4.months

effective_date = (filter_date-4.months).to_date.beginning_of_month

qs.filter_to_shop.filter_to_active.with_effective_date({"$gt" => effective_date}).eliminate_family_duplicates

qs.add({ "$match" => {"policy_purchased_at" => {"$gte" => filter_date}}})

enroll_pol_ids = []

qs.evaluate.each do |r|
    enroll_pol_ids << r['hbx_id']
end

total_count = enroll_pol_ids.size

count = 0

enroll_pol_ids.each do |pid|
  count += 1
  puts "#{Time.now} - #{count}/#{total_count}" if count % 100 == 0
  pol = HbxEnrollment.by_hbx_id(pid).first
  if pol.nil?
    raise "NO SUCH POLICY #{pid}"
  end
  if pol.plan.blank?
    puts "No plan for policy ID #{pid}: plan ID #{pol.plan_id}"
    #  elsif pol.subscriber.nil?
    #    puts "No subscriber for Policy ID #{pid}"
  else
    properties_slug = PropertiesSlug.new("", {:policy_id => pid})
    begin 
      controller.resource(ConnectionSlug.new(pid), "", properties_slug, "")
    rescue => e
      puts pid.inspect
      puts e.backtrace.inspect
    end
  end
end