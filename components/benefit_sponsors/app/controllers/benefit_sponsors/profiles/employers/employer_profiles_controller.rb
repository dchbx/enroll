module BenefitSponsors
  module Profiles
    module Employers
      class EmployerProfilesController < ::BenefitSponsors::ApplicationController

        before_action :find_employer, only: [:show, :inbox, :bulk_employee_upload, :export_census_employees, :coverage_reports, :download_invoice]
        before_action :load_group_enrollments, only: [:coverage_reports], if: :is_format_csv?
        before_action :check_and_download_invoice, only: [:download_invoice]
        layout "two_column", except: [:new]

        #New profile registration with existing organization and approval request submitted to employer
        def show_pending
          authorize BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new
          respond_to do |format|
            format.html
            format.js
          end
        end

        def show # TODO - Each when clause should be a seperate action.
          authorize @employer_profile
          @tab = params['tab']
          if (params[:q] || params[:page] || params[:commit] || params[:status]).present?
            # paginate_employees
          else
            case @tab
            when 'benefits'
              @benefit_sponsorship = @employer_profile.organization.active_benefit_sponsorship
              @benefit_applications = @employer_profile.benefit_applications.desc(:"start_on").asc(:predecessor_id)
            when 'documents'
              @datatable = ::Effective::Datatables::BenefitSponsorsEmployerDocumentsDataTable.new({employer_profile_id: @employer_profile.id})
              load_documents
            when 'employees'
              @datatable = ::Effective::Datatables::EmployeeDatatable.new(employee_datatable_params)
            when 'brokers'
              @broker_agency_account = @employer_profile.active_broker_agency_account
            when 'inbox'

            else
              @broker_agency_account = @employer_profile.active_broker_agency_account
              @benefit_sponsorship = @employer_profile.latest_benefit_sponsorship

              if @benefit_sponsorship.present?
                @broker_agency_accounts = @benefit_sponsorship.broker_agency_accounts
                @current_plan_year = @benefit_sponsorship.submitted_benefit_application
              end

              collect_and_sort_invoices(params[:sort_order])
              @sort_order = params[:sort_order].nil? || params[:sort_order] == "ASC" ? "DESC" : "ASC"

              respond_to do |format|
                format.html
                format.js
              end
            end
          end
        end

        def coverage_reports
          authorize @employer_profile
          @billing_date = Date.strptime(params[:billing_date], "%m/%d/%Y") if params[:billing_date]
          @datatable = ::Effective::Datatables::BenefitSponsorsCoverageReportsDataTable.new({ id: params.require(:employer_profile_id), billing_date: @billing_date})

          respond_to do |format|
            format.html
            format.js
            format.csv do
              send_data(csv_for(@group_enrollments), type: csv_content_type, filename: "DCHealthLink_Premium_Billing_Report.csv")
            end
          end
        end

        def export_census_employees
          authorize @employer_profile
          respond_to do |format|
            format.csv { send_data @employer_profile.census_employees.sorted.to_csv, filename: "#{@employer_profile.legal_name.parameterize.underscore}_census_employees_#{TimeKeeper.date_of_record}.csv" }
          end
        end

        def bulk_employee_upload
          authorize @employer_profile, :show?
          file = params.require(:file)
          @roster_upload_form = BenefitSponsors::Forms::RosterUploadForm.call(file, @employer_profile)
          begin
            if @roster_upload_form.save
              redirect_to @roster_upload_form.redirection_url
            else
              render :partial => @roster_upload_form.redirection_url
            end
          rescue Exception => e
            @roster_upload_form.errors.add(:base, e.message)
            render :partial => (@roster_upload_form.redirection_url || default_url)
          end
        end

        def inbox
          authorize @employer_profile
          @folder = params[:folder] || 'Inbox'
          @sent_box = false
        end

        def download_invoice
          options={}
          options[:content_type] = @invoice.type
          options[:filename] = @invoice.title
          send_data Aws::S3Storage.find(@invoice.identifier) , options
        end

        def generate_sic_tree
          sic_tree = SicCode.generate_sic_array
          render :json => sic_tree
        end

        private

        def check_and_download_invoice
          @invoice = @employer_profile.documents.find(params[:invoice_id])
        end

        def collect_and_sort_invoices(sort_order='ASC')
          @invoices = @employer_profile.invoices
          sort_order == 'ASC' ? @invoices.sort_by!(&:date) : @invoices.sort_by!(&:date).reverse! unless @documents
        end

        def find_employer
          id_params = params.permit(:id, :employer_profile_id)
          id = id_params[:id] || id_params[:employer_profile_id]
          @organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles._id" => BSON::ObjectId.from_string(id)).first
          @employer_profile = @organization.employer_profile
          render file: 'public/404.html', status: 404 if @employer_profile.blank?
        end

        def employee_datatable_params
          data_table_params = { id: params[:id], scopes: params[:scopes] }

          data_table_params.merge!({
            renewal: true
          }) if @employer_profile.renewing_published_benefit_application.present?

          data_table_params
        end

        def load_documents
          if @employer_profile.employer_attestation.present?
            @documents = @employer_profile.employer_attestation.employer_attestation_documents
          else
            @employer_profile.build_employer_attestation
          end
        end

        def load_group_enrollments
          billing_date = Date.strptime(params[:billing_date], "%m/%d/%Y") if params[:billing_date]
          query = Queries::CoverageReportsQuery.new(@employer_profile, billing_date)
          @group_enrollments =  query.execute
          @product_info = load_products
        end

        def load_products
          current_year = TimeKeeper.date_of_record.year
          previous_year = current_year - 1
          next_year = current_year + 1

          plans = BenefitMarkets::Products::Product.aca_shop_market.by_state(Settings.aca.state_abbreviation)

          current_possible_plans = plans.where(:"application_period.min".in =>[
            Date.new(previous_year, 1, 1),
            Date.new(current_year, 1, 1),
            Date.new(next_year, 1, 1)
          ])

          @product_info = current_possible_plans.inject({}) do |result, product|
            result[product.id] = {
              :title => product.title,
              :kind => product.kind,
              :issuer_name => product.issuer_profile.legal_name
            }
            result
          end
        end

        def default_url
          "/benefit_sponsors/profiles/employers/employer_profiles/employee_csv_upload_errors"
        end

        def csv_for(groups)
          (output = "").tap do
            CSV.generate(output) do |csv|
              csv << ["Name", "SSN", "DOB", "Hired On", "Benefit Group", "Type", "Name", "Issuer", "Covered Ct", "Employer Contribution",
              "Employee Premium", "Total Premium"]
              groups.each do |element|
                primary = element.primary_member
                census_employee = primary.employee_role.census_employee
                sponsored_benefit = primary.sponsored_benefit
                product = @product_info[element.group_enrollment.product[:id]]
                next if census_employee.blank?
                csv << [  
                          census_employee.full_name,
                          census_employee.ssn,
                          census_employee.dob,
                          census_employee.hired_on,
                          sponsored_benefit.benefit_package.title,
                          product[:kind],
                          product[:title],
                          product[:issuer_name],
                          (element.members.size - 1),
                          view_context.number_to_currency(element.group_enrollment.sponsor_contribution_total.to_s),
                          view_context.number_to_currency((element.group_enrollment.product_cost_total.to_f - element.group_enrollment.sponsor_contribution_total.to_f).to_s),
                          view_context.number_to_currency(element.group_enrollment.product_cost_total.to_s)
                        ]
              end
            end
          end
        end

        def csv_content_type
          case request.user_agent
            when /windows/i
              'application/vnd.ms-excel'
            else
              'text/csv'
          end
        end

        def is_format_csv?
          request.format.csv?
        end

        def user_not_authorized(exception)
          session[:custom_url] = main_app.new_user_registration_path unless current_user
          super
        end
      end
    end
  end
end
