class Exchanges::SecurityQuestionsController < ApplicationController
  layout 'single_column'

  def index
    @questions = SecurityQuestion.all
  end

  def new
    @question = SecurityQuestion.new
  end

  def create
    @question = SecurityQuestion.new(security_question_params)
    # binding.pry
    if @question.save
      redirect_to exchanges_security_questions_path, notice: 'Question was successfully created'
    else
      render :new
    end
  end

  def edit
    @question = SecurityQuestion.find(params[:id])
  end

  def update
    @question = SecurityQuestion.find(params[:id])
    if @question.safe_to_edit_or_delete? && @question.update_attributes(security_question_params)
      redirect_to exchanges_security_questions_path, notice: 'Question was updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @question = SecurityQuestion.find(params[:id])
    if @question.safe_to_edit_or_delete?
      @question.destroy
      notice = 'Question was deleted successfully.'
    else
      notice = 'That Question is already in use'
    end
    redirect_to exchanges_security_questions_path, notice: notice
  end

  private

  def security_question_params
    params.require(:security_question).permit(:title, :visible)
  end

  def set_question
    @question = SecurityQuestion.find(params[:id])
  end

end
