BUS_DIRECTORY = File.join(File.dirname(__FILE__), "..")
LOG_DIRECTORY = File.join(BUS_DIRECTORY, "log")
PID_DIRECTORY = File.join(BUS_DIRECTORY, "pids")

BLUEPILL_LOG = File.join(LOG_DIRECTORY, "eye_enroll.log")

Eye.config do
  logger BLUEPILL_LOG

  mail :host => "smtp4.dc.gov", :port => 25, :from_mail => "no-reply@dchbx.info"
  contact :tevans, :mail, 'trey.evans@dc.gov'
  contact :dthomas, :mail, 'dan.thomas@dc.gov'
end

def define_forked_worker(worker_name, directory, worker_command, watch_kids = false)
  process(worker_name) do
    start_command worker_command
    stop_on_delete true
    stop_signals [:TERM, 10.seconds, :KILL]
    start_timeout 5.seconds
    pid_file File.join(PID_DIRECTORY, "#{worker_name}.pid")
    daemonize true
    working_dir directory
    stdall File.join(LOG_DIRECTORY, "#{worker_name}.log")
    if watch_kids
      monitor_children do
        stop_command "/bin/kill -9 {PID}"
        check :memory, :every => 30, :below => 200.megabytes, :times => [3,5]
      end
    end
  end
end

Eye.application 'eye_enroll' do
  notify :tevans, :info
  notify :dthomas, :info

  define_forked_worker("broker_resource_listener", BUS_DIRECTORY, "bundle exec rails r -e production script/broker_resource_listener.rb", false)
  define_forked_worker("employer_resource_listener", BUS_DIRECTORY, "bundle exec rails r -e production script/employer_resource_listener.rb", false)
  define_forked_worker("individual_resource_listener", BUS_DIRECTORY, "bundle exec rails r -e production script/individual_resource_listener.rb", false)
  define_forked_worker("policy_resource_listener", BUS_DIRECTORY, "bundle exec rails r -e production script/policy_resource_listener.rb", false)
  define_forked_worker("policy_query_listener", BUS_DIRECTORY, "bundle exec rails r -e production script/policy_query_listener.rb", false)

  process("unicorn") do
    working_dir BUS_DIRECTORY
    pid_file "pids/unicorn.pid"
    start_command "bundle exec unicorn -c #{BUS_DIRECTORY}/config/unicorn.rb -E production -D"
    stdall "log/unicorn.log"

    # stop signals:
    #     # http://unicorn.bogomips.org/SIGNALS.html
    stop_signals [:TERM, 10.seconds]
    #
    #             # soft restart
    #    restart_command "kill -USR2 {PID}"
    #
    # check :cpu, :every => 30, :below => 80, :times => 3
    # check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    #
    start_timeout 30.seconds
    restart_grace 30.seconds
    stop_timeout 10.seconds
    #
    monitor_children do
      stop_command "kill -QUIT {PID}"
      check :cpu, :every => 30, :below => 95, :times => [3,5]
      check :memory, :every => 30, :below => 900.megabytes, :times => [4,7]
    end
  end

  process("enroll_remote_event_listener") do
    working_dir BUS_DIRECTORY
    pid_file "pids/enroll_remote_event_listener.pid"
    start_command "bundle exec rails runner -e production script/remote_event_listener.rb"
    stdall "log/enroll_remote_event_listener.log"
    trigger :flapping, times: 3, within: 1.minute, retry_in: 10.minutes
    daemonize true

    # stop signals:
    #     # http://unicorn.bogomips.org/SIGNALS.html
    stop_signals [:TERM, 10.seconds]
    #
    #             # soft restart
    #    restart_command "kill -USR2 {PID}"
    #
    # check :cpu, :every => 30, :below => 80, :times => 3
    # check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    #
    start_timeout 30.seconds
    restart_grace 30.seconds
    stop_timeout 10.seconds
  end
end
