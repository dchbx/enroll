class Exchanges::ResidentsController < ApplicationController

  def index
    @resident_enrollments = Person.where(:resident_enrollment_id.nin =>  ['', nil]).map(&:resident_enrollment)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
  end

  def match_person
  end
end
