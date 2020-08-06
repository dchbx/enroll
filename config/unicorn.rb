# frozen_string_literal: true

root_path = File.expand_path(File.join(File.dirname(__FILE__), ".."))
shared_path = File.expand_path(File.join(root_path, "..", "shared"))

working_directory root_path
pid shared_path + "/pids/unicorn.pid"
stderr_path shared_path + "/log/unicorn.log"
stdout_path shared_path + "/log/unicorn.log"

listen "/tmp/unicorn_enroll.ap.sock"
worker_processes 16
timeout 30
preload_app true

after_fork do |_server, _worker|
  Acapi::Requestor.reconnect!
  Acapi::LocalAmqpPublisher.reconnect!
end
