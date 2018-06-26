class Users::SecurityQuestionResponsesController < ApplicationController
  include Config::ContactCenterConcern

  def create
    responses = params[:security_question_responses]
    responses.each do |response|
      user.security_question_responses << SecurityQuestionResponse.new(security_question_id: response[:security_question_id], question_answer: response[:question_answer].downcase)
    end
    unless user.save!
      flash[:error] = "Something went wrong creating the security responses, try again please. Or contact #{contact_center_phone_number}"
      @url = request.referrer
      render :error_response
    end
  end

  def replace
    user.security_question_responses.destroy_all
    create
  end

  def challenge
    if user_from_email.nil?
      flash[:error] = "We can't find a user record with that email"
      render :error_response
    else
      @security_question = user_from_email.security_question_responses[rand(0..2)]

      if @security_question.nil?
        flash[:error] = "We have no security responses stored for this account, for assistance contact #{contact_center_phone_number}"
        render :error_response
      end
    end
  end

  def authenticate
    if challenge_question.matching_response? params[:security_question_response][:question_answer].downcase
      @success_token = challenge_question.success_token
      @form_name = "form#new_user"
      user.identity_confirmed_token = @success_token
      user.save!
    else
      flash[:error] = "That doesn't seem to be the correct response"
      render :error_response
    end
  end

  private
  helper_method :user_from_email, :challenge_question

  def challenge_question
    @challenge_question ||= user.security_question_responses.where(security_question_id: params[:security_question_response][:security_question_id]).first
  end

  def user
    @user ||= User.find(params[:user_id])
  end

  def user_from_email
    begin
      @user ||= User.find_by(email: params[:user][:email])
    rescue => e
      return
    end
  end
end
