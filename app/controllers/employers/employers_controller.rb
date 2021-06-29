# frozen_string_literal: true

module Employers
  class EmployersController < ApplicationController
    include ResourceConfigurator


    def search
      @employers = Organization.where(employer_profile: {:$exists => true}, legal_name: /^#{Regexp.escape(params[:q])}/i)

      result = @employers.limit(7).select{|org| Person.where({"employer_staff_roles.employer_profile_id" => org.employer_profile._id}).any?}
      render json: result
    end

    def redirect_to_new
      redirect_to new_employers_employer_profile_path
    end
  end
end
