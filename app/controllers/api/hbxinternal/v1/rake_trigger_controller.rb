class Api::Hbxinternal::V1::RakeTriggerController < ActionController::Base
  respond_to :json

  def say_hello
    response = {
      namespace: 'hbxinternal',
      desc:  'testing triggering rake execution from endpoint',
      task: 'trigger_from_endpoint'
    }
    system "rake hbxinternal:trigger_from_endpoint &"
    render json: response
  end

  def long_running_task
    response = {
      namespace: 'hbxinternal',
      desc:  'testing triggering long running rake execution from endpoint',
      task: 'process_long_running_task'
    }
    system "rake hbxinternal:process_long_running_task &"
    render json: response
  end

  def perform_task
    available_task = %w[change_person_dob]
    response = {}
    if available_task.include? params[:task]
      response[:status] = 200
      response[:message] = "Processing request"
      call_rake(params[:task], params)
    else
      response[:status] = 400
      response[:message] = "Improper request received"
    end
    render json: response

  end

  private

  def call_rake(task, options = {})
    options[:rails_env] = Rails.env
    str = ""
    options.each do |option|
      str += "#{option[0]}=#{option[1]} "
    end
    system "rake hbxinternal:#{task} #{str}"
  end
end
