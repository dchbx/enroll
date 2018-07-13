module BenefitSponsors
  module BenefitPackages
    class BenefitPackagesController < ApplicationController

      include Pundit

      layout "two_column"

      def new
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_new(params.require(:benefit_application_id))
        authorize @benefit_package_form, :updateable?
      end

      def create
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_create(benefit_package_params)
        authorize @benefit_package_form, :updateable?
        if @benefit_package_form.save
          flash[:notice] = "Benefit Package successfully created."
          if params[:add_new_benefit_package] == "true"
            redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_package_form.service.benefit_application.benefit_sponsorship, @benefit_package_form.show_page_model.benefit_application, add_new_benefit_package: true)
          else
            redirect_to profiles_employers_employer_profile_path(@benefit_package_form.service.employer_profile, :tab=>'benefits')
          end
        else
          flash[:error] = error_messages(@benefit_package_form)
          render :new
        end
      end

      def edit
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_edit(params.permit(:id, :benefit_application_id), true)
        authorize @benefit_package_form, :updateable?
      end

      def update
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_update(benefit_package_params.merge({:id => params.require(:id)}))
        authorize @benefit_package_form, :updateable?

        if @benefit_package_form.update
          flash[:notice] = "Benefit Package successfully updated."
          if params[:add_new_benefit_package] == "true"
            redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_package_form.service.benefit_application.benefit_sponsorship, @benefit_package_form.show_page_model.benefit_application, add_new_benefit_package: true)
          else
            redirect_to profiles_employers_employer_profile_path(@benefit_package_form.service.benefit_application.benefit_sponsorship.profile, :tab=>'benefits')
          end
        else
          flash[:error] = error_messages(@benefit_package_form)
          render :edit
        end
      end

      def calculate_employer_contributions
        @employer_contributions = BenefitSponsors::Forms::BenefitPackageForm.for_calculating_employer_contributions(benefit_package_params)
        render json: @employer_contributions
      end

      def calculate_employee_cost_details
        @employee_cost_details = BenefitSponsors::Forms::BenefitPackageForm.for_calculating_employee_cost_details(benefit_package_params)
        render json: @employee_cost_details.to_json
      end

      def destroy
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.fetch(params.permit(:id, :benefit_application_id))
        authorize @benefit_package_form, :updateable?
        if @benefit_package_form.destroy
          flash[:notice] = "Benefit Package successfully deleted."
          render :js => "window.location = #{profiles_employers_employer_profile_path(@benefit_package_form.service.benefit_application.benefit_sponsorship.profile, :tab=>'benefits').to_json}"
        else
          flash[:error] = error_messages(@benefit_package_form)
          render :js => "window.location = #{profiles_employers_employer_profile_path(@benefit_package_form.service.benefit_application.benefit_sponsorship.profile, :tab=>'benefits').to_json}"
        end
      end

      def reference_product_summary
        @product_summary = BenefitSponsors::Forms::BenefitPackageForm.for_reference_product_summary(reference_product_params, params[:details])
        render json: @product_summary
      end

      private

      def error_messages(object)
        object.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def benefit_package_params
        params.require(:benefit_package).permit(
          :title, :description, :probation_period_kind, :benefit_application_id, :id,
          :sponsored_benefits_attributes => [:id, :kind, :product_option_choice, :product_package_kind, :reference_plan_id,
            :sponsor_contribution_attributes => [ 
              :contribution_levels_attributes => [:id, :is_offered, :display_name, :contribution_factor,:contribution_unit_id]
            ]
          ]
        )
      end

      def reference_product_params
        params.permit(:benefit_application_id).merge({:sponsored_benefits_attributes => {"0" => {:reference_plan_id => params[:reference_plan_id]} }})
      end

      def employer_contribution_params
        params.permit(:id, :benefit_application_id, :sponsored_benefits_attributes => [:product_package_kind, :reference_plan_id, :id])
      end
    end
  end
end
