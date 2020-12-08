# RAILS_ENV=production bundle exec rake hbxinternal:trigger_from_endpoint

# /api/hbxinternal/v1/trigger_from_endpoint


namespace :hbxinternal do
  desc "testing triggering rake execution from endpoint"
  task :trigger_from_endpoint => :environment do
    puts "running hbxinternal rake task at #{Time.now}"
    hbxit_broker_uri = Settings.hbxit.rabbit.uri
    target_queue = 'mafia'

    conn = Bunny.new(hbxit_broker_uri, :heartbeat => 15)
    conn.start
    chan = conn.create_channel
    queue = chan.queue('dev')
    chan.confirm_select
    chan.default_exchange.publish("Initiating rake task: trigger_from_endpoint by Andrej Rasevic at #{Time.now}",routing_key: queue.name)
    sleep 4
    puts "ending hbxinternal rake task"
    chan.default_exchange.publish("Ending rake task: trigger_from_endpoint successfully by Andrej Rasevic at #{Time.now}",routing_key: queue.name)
    chan.wait_for_confirms
    conn.close
  end

  task :change_person_dob => :environment do
    if ENV['hbx_id'] && ENV['dob']
      begin
        person = Person.where(hbx_id:ENV['hbx_id']).first
        raise StandardError.new "Unable to locate a person with HBXID: #{ENV['hbx_id']}" if person.nil?
        ActionCable.server.broadcast 'notifications_channel', message: "1/3 Located person record for #{ENV['hbx_id']}"
        notify_broker ENV['task']
      rescue => error
        ActionCable.server.broadcast 'notifications_channel', message: error.message
      else
        ActionCable.server.broadcast 'notifications_channel', message: "2/3 Updated DOB for person record"
        new_dob = Date.strptime(ENV['dob'],'%m/%d/%Y')
        person.update_attributes(dob:new_dob)
        ActionCable.server.broadcast 'notifications_channel', message: '3/3 Task complete you may close console.'
        close_broker_connection ENV['task']
      end
    else
      raise StandardError.new "Missing fields to perform change person dob task."
    end
  end

  task :remove_person_ssn => :environment do
    endpoint = Settings.hbxit.api.uri + '/rakeTaskTriggerHistories'
    if ENV['hbx_id']
      begin
        person = Person.where(hbx_id:ENV['hbx_id']).first
        close_broker_connection_with_error(ENV['task'], "Unable to locate a person with HBXID: #{ENV['hbx_id']}") if person.nil?
        HTTParty.put(endpoint,
              :body => {:rakeTaskResultId => ENV['newRakeTaskId'], :taskStatus => "Completed-Failure: Unable to locate person with HBXID: #{ENV['hbx_id']}"}.to_json,
              :headers => {'Content-Type' => 'application/json'} 
              ) if person.nil?
        raise StandardError.new "Unable to locate a person with HBXID: #{ENV['hbx_id']}" if person.nil?
        ActionCable.server.broadcast 'notifications_channel', message: "1/3 Located person record for #{ENV['hbx_id']}"
        notify_broker ENV['task']
      rescue => error
        ActionCable.server.broadcast 'notifications_channel', message: error.message
      else
        ActionCable.server.broadcast 'notifications_channel', message: "2/3 Remove ssn from person with HBX ID #{ENV['hbx_id']}"
        person.unset(:encrypted_ssn)
        ActionCable.server.broadcast 'notifications_channel', message: '3/3 Task complete you may close console.'
        HTTParty.put(endpoint,
              :body => {:rakeTaskResultId => ENV['newRakeTaskId'], :taskStatus => 'Completed-Success'}.to_json,
              :headers => {'Content-Type' => 'application/json'}
              )
        close_broker_connection ENV['task']
      end
    else
      close_broker_connection_with_error(ENV['task'], "Missing fields to perform remove person ssn task")
      HTTParty.put(endpoint,
              :body => {:rakeTaskResultId => ENV['newRakeTaskId'], :taskStatus => 'Completed-Failure: Missing Fields'}.to_json,
              :headers => {'Content-Type' => 'application/json'} 
              ) 
      raise StandardError.new "Missing fields to perform remove person ssn task."
    end
  end

  task :exchange_ssn_between_two_accounts => :environment do
    if ENV['hbx_id_1'] && ENV['hbx_id_2']
      begin
        person1 = Person.where(hbx_id: ENV['hbx_id_1']).first
        person2 = Person.where(hbx_id: ENV['hbx_id_2']).first
        raise StandardError.new "Unable to locate a person with HBXID: #{ENV['hbx_id_1']}" if person1.nil?
        raise StandardError.new "Unable to locate a person with HBXID: #{ENV['hbx_id_2']}" if person2.nil?
        ActionCable.server.broadcast 'notifications_channel', message: "1/3 Located persons record for #{ENV['hbx_id_1']} and #{ENV['hbx_id_2']}"
        notify_broker ENV['task']
      rescue => error
        ActionCable.server.broadcast 'notifications_channel', message: error.message
      else
        ssn1 = person1.ssn
        ssn2 = person2.ssn
        raise StandardError.new "Person with HBXID: #{ENV['hbx_id_1']} has no ssn" if ssn1.nil?
        raise StandardError.new "Person with HBXID: #{ENV['hbx_id_2']} has no ssn" if ssn2.nil?
        ActionCable.server.broadcast 'notifications_channel', message: "2/3 Moving SSN's between accounts"
        person1.unset(:encrypted_ssn)
        person2.unset(:encrypted_ssn)
        person1.update_attributes(ssn: ssn2)
        person2.update_attributes(ssn: ssn1)
        ActionCable.server.broadcast 'notifications_channel', message: "3/3 Task complete you may close console"
        close_broker_connection ENV['task']
      end
    else
      raise StandardError.new "Missing fields to perform exchange ssn between two accounts task."
    end
  end

  task :move_user_account_between_two_people_accounts => :environment do
    if ENV['hbx_id_1'] && ENV['hbx_id_2']
      begin
        person1 = Person.where(hbx_id: ENV['hbx_id_1']).first
        person2 = Person.where(hbx_id: ENV['hbx_id_2']).first
        raise StandardError.new "Unable to locate a person with HBXID: #{ENV['hbx_id_1']}" if person1.nil?
        raise StandardError.new "Unable to locate a person with HBXID: #{ENV['hbx_id_2']}" if person2.nil?
        ActionCable.server.broadcast 'notifications_channel', message: "1/3 Located persons record for #{ENV['hbx_id_1']} and #{ENV['hbx_id_2']}"
        notify_broker ENV['task']
      rescue => error
        ActionCable.server.broadcast 'notifications_channel', message: error.message
      else
        user = person1.user
        raise StandardError.new "Person with HBXID: #{ENV['hbx_id_1']} has no user" if user.nil?
        ActionCable.server.broadcast 'notifications_channel', message: "2/3 Moving user account between person accounts"
        person1.unset(:user_id)
        person2.set(user_id: user.id)
        sleep 1
        ActionCable.server.broadcast 'notifications_channel', message: "3/3 Task complete you may close console"
        close_broker_connection ENV['task']
      end
    else
      raise StandardError.new "Missing fields to perform move user account between two people task."
    end
  end

  task :change_ce_date_of_termination => :environment do
    if ENV['ssn'] && ENV['date_of_terminate']
      begin
        census_employee = CensusEmployee.by_ssn(ENV['ssn']).first
        new_termination_date = Date.strptime(ENV['date_of_terminate'],'%m/%d/%Y').to_date
        raise StandardError.new "No census employee was found with ssn provided" if census_employee.nil?
        raise StandardError.new "The census employee is not in employment terminated state" if census_employee.aasm_state != "employment_terminated"
        ActionCable.server.broadcast 'notifications_channel', message: "1/4 Located census employee record"
        notify_broker ENV['task']
      rescue => error
        ActionCable.server.broadcast 'notifications_channel', message: error.message
      else
        ActionCable.server.broadcast 'notifications_channel', message: "2/4 Updating termination date"
        census_employee.update_attributes(employment_terminated_on: new_termination_date)
        ActionCable.server.broadcast 'notifications_channel', message: "3/4 Successfully updated termination date"
        sleep 1
        ActionCable.server.broadcast 'notifications_channel', message: "4/4 Task complete you may close console"
        close_broker_connection ENV['task']
      end
    else
      raise StandardError.new "Missing fields to perform change census employee date of termination task."
    end
  end

  task :employers_failing_minimum_participation => :environment do
    begin
      ActionCable.server.broadcast 'notifications_channel', message: "... Generating Employers Failing Minimum Participation report ..."
      Rake::Task['reports:shop:employers_failing_minimum_participation'].invoke
      notify_broker ENV['task']
    rescue => error
      ActionCable.server.broadcast 'notifications_channel', message: error.message
    else
      ActionCable.server.broadcast 'notifications_channel', message: "... Completed report generation ..."
      close_broker_connection ENV['task']
    end
  end

  task :employers_export do
    begin
      puts "Starting exporting employers"
      Rake::Task['employers:export'].invoke
      notify_broker ENV['task']
    rescue => error
      puts "Error #{error}"
    ensure
      puts "Done exporting employers"
      close_broker_connection ENV['task']
    end
  end

  task :employer_roster_export do
    begin
      Rake::Task['reports:shop:internal_employer_roster_report'].invoke
      notify_broker ENV['task']
    rescue => error
      puts "Error #{error}"
    ensure
      close_broker_connection ENV['task']
    end
  end

  task :shop_monthly_enrollments do
    begin
      Rake::Task['reports:internal_shop_monthly_enrollments'].invoke
      notify_broker ENV['task']
    rescue => error
      puts "Error #{error}"
    ensure
      close_broker_connection ENV['task']
    end
  end

  task :internal_er_plan_year_status do
    begin
      Rake::Task['reports:shop:internal_er_plan_year_status'].invoke
      notify_broker ENV['task']
    rescue => error
      puts "Error #{error}"
    ensure
      close_broker_connection ENV['task']
    end
  end

  def notify_broker(task)
    hbxit_broker_uri = Settings.hbxit.rabbit.uri
    target_queue = 'mafia'
    conn = Bunny.new(hbxit_broker_uri, :heartbeat => 15)
    conn.start
    chan = conn.create_channel
    queue = chan.queue('dev')
    chan.confirm_select
    chan.default_exchange.publish("Initiating rake task: #{task} by Admin Client at #{Time.now}",routing_key: queue.name)
  end

  def close_broker_connection(task)
    puts "ending #{task} rake task"
    hbxit_broker_uri = Settings.hbxit.rabbit.uri
    target_queue = 'mafia'
    conn = Bunny.new(hbxit_broker_uri, :heartbeat => 15)
    conn.start
    chan = conn.create_channel
    queue = chan.queue('dev')
    chan.confirm_select
    chan.default_exchange.publish("Ending rake task: #{task} successfully by Admin Client at #{Time.now}",routing_key: queue.name)
    chan.wait_for_confirms
    conn.close
  end

  def close_broker_connection_with_error(task, error)
    puts "ending #{task} rake task with error: #{error}"
    hbxit_broker_uri = Settings.hbxit.rabbit.uri
    target_queue = 'mafia'
    conn = Bunny.new(hbxit_broker_uri, :heartbeat => 15)
    conn.start
    chan = conn.create_channel
    queue = chan.queue('dev')
    chan.confirm_select
    chan.default_exchange.publish("Ending rake task: #{task} unsuccessfully at #{Time.now}.\n
      Error: #{error}",routing_key: queue.name)
    chan.wait_for_confirms
    conn.close
  end

end
