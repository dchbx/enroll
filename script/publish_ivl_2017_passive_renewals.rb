amqp_environment_name = "preprod"
window_start = Time.mktime(2016,10,31,0,0,0)
window_end = Time.mktime(2016, 12, 1, 12, 0, 0)

qs = Queries::PolicyAggregationPipeline.new

qs.filter_to_individual.filter_to_active.with_effective_date({"$gt" => Date.new(2016,12,31)}).eliminate_family_duplicates

qs.add({ "$match" => {"policy_purchased_at" => {"$gt" => window_start, "$lte" => window_end}}})

enroll_pol_ids = []

qs.evaluate.each do |r|
  if r['aasm_state'] == "auto_renewing"
    enroll_pol_ids << r['hbx_id']
  end
end

remote_broker_uri = Rails.application.config.acapi.remote_broker_uri
target_queue = "dc0.#{amqp_environment_name}.q.gluedb.enrollment_query_result_handler"

conn = Bunny.new(remote_broker_uri, :heartbeat => 15)
conn.start
chan = conn.create_channel
chan.confirm_select
dex = chan.default_exchange
enroll_pol_ids.each do |pol_id|
 dex.publish(
   "",
   {
     :routing_key => target_queue,
     :headers => { 
       "hbx_enrollment_id" => pol_id.to_s,
       "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#auto_renew"
     }
   }
 )
 chan.wait_for_confirms
end
conn.close
