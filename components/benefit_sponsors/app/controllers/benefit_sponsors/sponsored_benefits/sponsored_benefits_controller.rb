# frozen_string_literal: true

module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitsController < ApplicationController

      layout "two_column"

      # before_action :find_benefit_application, :find_employer

      def new
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_new_benefit(params.permit(:kind, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id))
        # TODO: - add pundit policy
      end

      def create
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_create(identifier_params.merge(sponsored_benefits_params))
        # TODO: - add pundit policy

        if @sponsored_benefit_form.save
          flash[:notice] = "Benefit Package successfully created."
          redirect_to profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab => 'benefits')
        else
          flash[:error] = error_messages(@sponsored_benefit_form)
          @sponsored_benefit_form.load_meta_data
          render :new
        end
      end

      def edit
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_edit(params.permit(:kind, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id, :id))
        # TODO: - add pundit policy
      end

      def update
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_update(identifier_params.merge(sponsored_benefits_params))
        # TODO: - add pundit policy
        if @sponsored_benefit_form.update
          flash[:notice] = "Benefit Package successfully updated."
          redirect_to profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab => 'benefits')
        else
          flash[:error] = error_messages(@sponsored_benefit_form)
          render :edit
        end
      end

      def destroy
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_destroy(params.permit(:kind, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id, :id))

        if @sponsored_benefit_form.destroy
          flash[:notice] = "Dental Benefit Package successfully deleted."
          redirect_to profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab => 'benefits')
        #  render :js => "window.location = #{profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab=>'benefits').to_json}"
        else
          flash[:error] = error_messages(@sponsored_benefit_form)
        #  render :js => "window.location = #{profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab=>'benefits').to_json}"
        end
      end

      def calculate_employer_contributions
        @employer_contributions = BenefitSponsors::Forms::SponsoredBenefitForm.for_calculating_employer_contributions(benefit_params)
        render json: @employer_contributions
      end

      def calculate_employee_cost_details
        @employee_cost_details = BenefitSponsors::Forms::SponsoredBenefitForm.for_calculating_employee_cost_details(benefit_params)
        render json: @employee_cost_details.to_json
      end

      private

      def error_messages(object)
        object.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def identifier_params
        params.permit(:id, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id)
      end

      def sponsored_benefits_params
        params.require(:sponsored_benefits).permit(
          :id, :kind, :product_option_choice,
          :product_package_kind, :reference_plan_id, :elected_product_choices => [],
                                                     :sponsor_contribution_attributes => [
            :contribution_levels_attributes => [:id, :is_offered, :display_name, :contribution_factor,:contribution_unit_id]
          ]
        )
      end

      def benefit_params
        product_package_kind = params.require(:sponsored_benefits).require(:sponsored_benefits_attributes).require('0').permit(:product_package_kind)
        params.permit(:benefit_sponsorship_id, :benefit_application_id, :benefit_package_id).merge(sponsored_benefits_params).merge(product_package_kind)
      end
    end
  end
end
