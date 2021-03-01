class HbxitTaskWorker
  include Sidekiq::Worker

  def perform(*args)
    data = JSON.parse(args[0])
    task = data['task'].to_sym
    options_str = options_to_string(data)
    perform_task task, options_str
  end

  def options_to_string(options)
    str = ""
    options.each do |option|
      str += "#{option[0]}=#{option[1]} "
    end
    str
  end

  def perform_task(task, options)
    system "rake hbxinternal:#{task} #{options}"
  end

  private

  def around_cleanup
    # Do something before perform
    # SQS beging messaging
    # ActionCable.server.broadcast 'notifications_channel', message: "Starting Job"
    yield
    # Do something after perform
    # SQS end messaging
    # ActionCable.server.broadcast 'notifications_channel', message: "Job has completed"
  end
end
