# frozen_string_literal: true

class PortalsController < ApplicationController

  layout 'bootstrap_4_two_column'

  before_action :find_person

  def index
    @person = Person.find(params[:id])
  end

  def show; end


  private

  def find_person
    @person = Person.find(params[:id])
  end

end