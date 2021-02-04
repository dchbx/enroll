# frozen_string_literal: true

# Controller with user facing interface for creating, editing, and destroying translations
# Currently can only be visited by super admin users

class TranslationsController < ApplicationController
  before_action :translations_authorized?
  before_action :set_translation, only: [:show, :edit, :update, :destroy]

  def index
    @translations = Translation.order('key ASC').all
  end

  def show; end

  def new
    @translation = Translation.new
  end

  def create
    @translation = Translation.new(translation_params)
    respond_to do |format|
      if @translation.save
        format.html { redirect_to @translation, notice: 'Translation was successfully created.' }
        format.json { render :index, status: :created, location: @translation }
      else
        format.html { render :new }
        format.json { render json: @translation.errors, status: :unprocessable_entity }
      end
    end
    # I18n.backend.store_translations(params[:locale], {params[:key] => params[:value]}, escape: false)
    # redirect_to translations_path, :notice => "Added translations"
  end

  def edit; end

  def update
    respond_to do |format|
      if @translation.update(translation_params)
        format.html { redirect_to @translation, notice: 'Translation was successfully updated.' }
        format.json { render :show, status: :ok, location: @translation }
      else
        format.html { render :edit }
        format.json { render json: @translation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @translation.destroy
    respond_to do |format|
      format.html { redirect_to translations_url, notice: 'Translation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Best to keep the scope of this controller down to super admins
  def translations_authorized?
    authorize(HbxProfile, :can_view_or_change_translations?)
  end

  def set_translation
    @translation = Translation.find(params[:id])
  end

  def translation_params
    params.require(:translation).permit(:key, :value)
  end
end

