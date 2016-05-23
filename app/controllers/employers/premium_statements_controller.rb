require 'csv'
require 'prawn/table'
class Employers::PremiumStatementsController < ApplicationController
  layout "two_column", only: [:show]
  include PrawnHelper

  def show
    @employer_profile = EmployerProfile.find(params.require(:id))
    @hbx_enrollments = @employer_profile.enrollments_for_billing

    respond_to do |format|
      format.html
      format.js
      format.csv do
        send_data(csv_for(@hbx_enrollments), type: csv_content_type, filename: "DCHealthLink_Premium_Billing_Report.csv")
      end
      format.pdf do
        filename = File.join(Rails.root, "tmp", "DCHealthLink_Premium_Billing_Report_#{Time.new.to_i}.pdf")
        pdf_file =pdf_for(@hbx_enrollments)
        pdf_file.render_file filename
        send_file  filename, :type => "application/pdf"
      end
    end
  end

  private

  def csv_for(hbx_enrollments)
    (output = "").tap do
      CSV.generate(output) do |csv|
        csv << ["Name", "SSN", "DOB", "Hired On", "Benefit Group", "Type", "Name", "Issuer", "Covered Ct", "Employer Contribution",
        "Employee Premium", "Total Premium"]
        hbx_enrollments.each do |enrollment|
          ee = enrollment.census_employee
          next if ee.blank?
          csv << [  ee.full_name,
                    ee.ssn,
                    ee.dob,
                    ee.hired_on,
                    ee.published_benefit_group.title,
                    enrollment.plan.coverage_kind,
                    enrollment.plan.name,
                    enrollment.plan.carrier_profile.legal_name,
                    enrollment.humanized_members_summary,
                    view_context.number_to_currency(enrollment.total_employer_contribution),
                    view_context.number_to_currency(enrollment.total_employee_cost),
                    view_context.number_to_currency(enrollment.total_premium)
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

  def pdf_for(hbx_enrollments)
    enrollment_summary = hbx_enrollments.inject({}) do |hash,enrollment| 
      if hash.include?(enrollment.plan.name)
         hash[enrollment.plan.name]["employee_count"] += 1
         hash[enrollment.plan.name]["dependents_count"] += enrollment.humanized_dependent_summary
         hash[enrollment.plan.name]["total_employer_contribution"] += enrollment.total_employer_contribution
         hash[enrollment.plan.name]["total_employee_cost"] += enrollment.total_employee_cost
         hash[enrollment.plan.name]["total_premium"] += enrollment.total_premium
      else
        hash[enrollment.plan.name] = {}
        hash[enrollment.plan.name]["enrollments"] = []
        hash[enrollment.plan.name]["issuer"] = enrollment.plan.carrier_profile.legal_name
        hash[enrollment.plan.name]["employee_count"] = 1
        hash[enrollment.plan.name]["dependents_count"] = enrollment.humanized_dependent_summary
        hash[enrollment.plan.name]["total_employer_contribution"] = enrollment.total_employer_contribution
        hash[enrollment.plan.name]["total_employee_cost"] = enrollment.total_employee_cost
        hash[enrollment.plan.name]["total_premium"] = enrollment.total_premium
      end
      hash[enrollment.plan.name]["enrollments"] << enrollment
      hash
    end


    @pdf=Prawn::Document.new
    cheque_amount_path = 'app/assets/images/cheque_amount.png'
    logopath = 'app/assets/images/logo.png'
    initial_y = @pdf.cursor
    initialmove_y = 25
    address_x = 15
    lineheight_y = 12
    font_size = 12
    
    @pdf.move_down initialmove_y
    @pdf.font "Helvetica"
    @pdf.font_size font_size

    @pdf.text_box "DC Health Link", :at => [address_x,  @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box "PO Box 97022", :at => [address_x,  @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box "Washington, DC 20090", :at => [address_x,  @pdf.cursor]
    @pdf.move_down lineheight_y

    last_measured_y = @pdf.cursor
    @pdf.move_cursor_to @pdf.bounds.height
    @pdf.move_cursor_to last_measured_y
   
    @pdf.move_down 155
    address = @employer_profile.try(:organization).try(:office_locations).first.address 
    @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x,  @pdf.cursor]
    if address
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.address_1}", :at => [address_x,  @pdf.cursor]
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.address_2}", :at => [address_x,  @pdf.cursor]
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x,  @pdf.cursor]
    end

    ###############################################################################################
    @pdf.start_new_page

    invoice_header_x = 275
    activity_header_x = 275
    logo_x = 360
    cheque_amount_path_x = 350

    
    @pdf.move_down initialmove_y

    @pdf.text_box "Statement Date: #{DateTime.now.strftime("%D")}", :at => [address_x, @pdf.cursor], :style => :bold
    
    @pdf.move_down 36
    #Image
    @pdf.image logopath, :width => 150, :at => [address_x,  @pdf.cursor]
    invoice_header_data = [ 
      ["ACCOUNT NUMBER:", "#{@employer_profile.organization.hbx_id}"],
      ["TOTAL AMOUNT DUE:", "#{hbx_enrollments.map(&:total_premium).sum}"],
      ["DATE DUE:", "#{DateTime.now.end_of_month.strftime("%m/14/%Y")}"]
    ]

    dchbx_table_light_blue(invoice_header_data,invoice_header_x)
    
    @pdf.move_down 40

    # activity_header_data = [ 
    #   ["Activity since your last statement", ""],
    #   ["Previous Balance", "$1,234. 00"],
    #   ["Amount Paid", "$3,200.00"],
    #   ["Adjustments", "$478.34"],
    #   ["New Charges", "$534"],
    #   ["Total Amount Due","$234"]
    # ]
    # dchbx_table_with_border(activity_header_data,activity_header_x)

    address = @employer_profile.try(:organization).try(:office_locations).first.address 
    @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x, 585]
    if address
      @pdf.text_box "#{address.address_1}", :at => [address_x, 573]
      @pdf.text_box "#{address.address_2}", :at => [address_x, 561]
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 549]
    end

    @pdf.move_down 54

    @pdf.text_box "Please review the billing summary. This is a consolidated bill for all your benefits through DC Health Link. Please pay the Total Amount Due.", :at => [address_x, @pdf.cursor]
    @pdf.move_down 48
    @pdf.text_box "Payment Options", :at => [address_x, @pdf.cursor], :style => :bold
    @pdf.move_down 24
    @pdf.text_box "Make a secure online electronic check payment. Use the account number found at the top of your invoice to login at:", :at => [address_x, @pdf.cursor]
    @pdf.move_down 36
    @pdf.text_box "https://www.e-BillExpress.com/ebpp/DCHealthPay", :at => [address_x, @pdf.cursor], :align => :center
    @pdf.move_down 24
    @pdf.text_box "Return the attached payment coupon with a personal, business, or cashier’s check for prompt, accurate and timely posting of your payment. Address payments to:", :at => [address_x, @pdf.cursor]
    @pdf.move_down 36
    @pdf.text_box "Call DC Health Link Customer Service at 855-532-5465", :at => [address_x, @pdf.cursor]
    @pdf.move_down 72
    @pdf.text_box "PLEASE DETACH HERE AND RETURN THE BOTTOM PORTION WITH YOUR PAYMENT", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold

    @pdf.move_down 36

    @pdf.image logopath, :width => 150, :at => [logo_x, @pdf.cursor]

    dchbx_table_light_blue(invoice_header_data,address_x)

    @pdf.move_down 18
    @pdf.text_box "Amount Enclosed:", :at => [address_x, 136], :align => :center, :style => :bold
    @pdf.image cheque_amount_path, :width => 160, :at => [cheque_amount_path_x, 142]

    @pdf.text_box "DC Health Link", :at => [320,  72]
    @pdf.text_box "PO Box 97022", :at => [320,  60]
    @pdf.text_box "Washington, DC 20090", :at => [320,  48]
    
    address = @employer_profile.try(:organization).try(:office_locations).first.address 
    @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x, 72]
    if address
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.address_1}", :at => [address_x, 60]
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.address_2}", :at => [address_x, 48]
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 36]
    end

###############################################################################################    
    @pdf.start_new_page
    
    @pdf.move_down initialmove_y

    @pdf.image logopath, :width => 150
    # @pdf.move_down 60

    @pdf.text_box "#{DateTime.now.next_month.strftime("%B")} Group Coverage Bill", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold

    @pdf.move_down 60

    #Add payment table here
    # last_premium_payment = @employer_profile.try(:employer_profile_account).try(:premium_payments).last 

    # if last_premium_payment.present?
    #   invoice_last_payment_data = [ 
    #     ["Payment Date", "Payment Method", "Description", "Amount"]
    #   ]
    #   invoice_last_payment_data << [last_premium_payment[:paid_on], last_premium_payment[:method_kind], "Payment Received" ,last_premium_payment[:amount]]
    #   dchbx_table_item_list(invoice_last_payment_data)
    # end
  
    invoice_services_data = [ 
      [" ", "Covered Subscribers", "Covered Dependents", "New Charges"]
    ]
    enrollment_summary.each do |name,plan_summary| 
      invoice_services_data << ["#{name}", "#{plan_summary['employee_count']}", "#{plan_summary['dependents_count']}", "#{plan_summary['total_premium']}"]

    end

    dchbx_table_item_list(invoice_services_data)
    @pdf.move_down 5
    @pdf.text_box "New Charges Total", :at => [0, @pdf.cursor], :style => :bold
    @pdf.text "#{hbx_enrollments.map(&:total_premium).sum}" , :align => :right, :style => :bold
    # @pdf.text "#{summary['total_premium']}"

############################################################################################################   

    enrollment_summary.each do |name, summary| 
      carrier_plan_services_data = [ 
        ["Last 4 SSN", "Name", "No. of Enrolled (1=EE only)", "Coverage Month", "Employer Cost", "Employee Cost", "Premium"]
      ]

      @pdf.start_new_page

      @pdf.move_down initialmove_y
      
      @pdf.image logopath, :width => 150

      @pdf.move_down 48
      @pdf.text_box "Carrier Plan Summary", :align => :center, :style => :bold, :at => [address_x, @pdf.cursor]

      @pdf.move_down 24

      #Name of the Plan
      #@pdf.text "#{name}", :align => :right
    
      plan_header_data = [
        ["Insurance Carrier Plan","" ,"#{name}"]
      ]

      dchbx_plan_header(plan_header_data)

       @pdf.move_down 24

       @pdf.text_box "Subscriber(s) and Adjustment(s) for Coverage Period: #{DateTime.now.next_month.strftime("%B")}", :style => :bold, :at => [0, @pdf.cursor]

       @pdf.move_down 24

      summary["enrollments"].each do |enrollment|
        subscriber = enrollment.subscriber.person.employee_roles.try(:first).try(:census_employee)
        carrier_plan_services_data << ["#{subscriber.ssn.split(//).last(4).join}", "#{subscriber.full_name}", "#{enrollment.humanized_dependent_summary}", "Add","#{enrollment.total_employer_contribution}" ,"#{enrollment.total_employee_cost}"  ,"#{enrollment.total_premium}"]
        #@pdf.text "#{summary['total_premium']}"
      end

      dchbx_table_by_plan(carrier_plan_services_data)

      @pdf.move_down 5
      @pdf.text_box "PLAN TOTAL", :at => [0, @pdf.cursor], :style => :bold
      @pdf.text "#{summary['total_premium']}", :align => :right, :style => :bold

    end
   #########################################################################################
   
#     @pdf.start_new_page
    
#     @pdf.move_down initialmove_y

#     @pdf.text_box "DC Health Link", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y
#     @pdf.text_box "PO Box 97022", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y
#     @pdf.text_box "Washington, DC 20090", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y

#     last_measured_y = @pdf.cursor
#     @pdf.move_cursor_to @pdf.bounds.height

#     @pdf.move_cursor_to last_measured_y
   
#     @pdf.move_down 155
#     last_measured_y = @pdf.cursor

#     address = @employer_profile.try(:organization).try(:office_locations).first.address 
#     @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x,  @pdf.cursor]
#     if address
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.address_1}", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.address_2}", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x,  @pdf.cursor]
#     end

#    ######################################################################################################################
#     @pdf.start_new_page

#     last_measured_y = @pdf.cursor
#     @pdf.move_cursor_to @pdf.bounds.height

#     @pdf.move_cursor_to last_measured_y
   
#     @pdf.move_down initialmove_y  
#     @pdf.text_box "Notice Date: <xx>/15/<xxxx>", :at => [address_x, @pdf.cursor], :style => :bold

#     @pdf.move_down 36

#     @pdf.image logopath, :width => 150, :at => [address_x,  @pdf.cursor]

#     @pdf.move_down 66

#     late_payment_invoice_header_data = [ 
#       ["Account Number:", "<1234 1234>"],
#       ["Original Invoice Data:", "<Date>"],
#       ["Coverage Period:", "<$3,200.00 USD>"],
#       ["Past Due Amount:", "<$2,323.00USD>"],
#       ["Due Date:", "<March 31, 2016>"],
#     ]
#     dchbx_table_light_blue(late_payment_invoice_header_data, invoice_header_x)

#     address = @employer_profile.try(:organization).try(:office_locations).first.address 
#     @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x, 585]
#     if address
#       @pdf.text_box "#{address.address_1}", :at => [address_x, 573]
#       @pdf.text_box "#{address.address_2}", :at => [address_x, 561]
#       @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 549]
#     end

#     @pdf.move_down 36

#     @pdf.text_box "Late Payment Notice-Action Required", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold
#     @pdf.move_down 24
#     @pdf.text_box "Dear NAME,", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 24
#     @pdf.text_box "As of the date of this notice, our records indicate we have not yet received a full premium payment for <January> health care benefits though DC Health Link.", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 36
#     @pdf.text_box "Please pay your premium by <February 29, 2016> or health coverage for your employees will be canceled retroactively effective <December 31, 2015>.", :at => [address_x, @pdf.cursor], :style => :bold
#     @pdf.move_down 36
#     @pdf.text_box "If you do not pay in full by <January 25, 2016>, your employees will receive notices informing them of non- payment and the possibility of losing their healthcoverage.", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 48
#     @pdf.text_box "If you have already sent your full premium payment, please disregard this notice.", :at => [address_x, @pdf.cursor], :align => :center
#     @pdf.move_down 24
#     @pdf.text_box "See reverse side for payment options.", :at => [address_x, @pdf.cursor], :align => :center, :style => :italic
#     @pdf.move_down 36
#     @pdf.text_box "PLEASE RETURN THE BOTTOM PORTION WITH YOUR PAYMENT", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold
#     @pdf.move_down 48

#     @pdf.image logopath, :width => 150, :at => [logo_x,  @pdf.cursor]

#     dchbx_table_light_blue(invoice_header_data,address_x)

#     @pdf.move_down 18
#     @pdf.text_box "Amount Enclosed:", :at => [address_x, 123], :align => :center, :style => :bold
#     @pdf.image cheque_amount_path, :width => 160, :at => [cheque_amount_path_x, @pdf.cursor]

#     @pdf.text_box "DC Health Link", :at => [320,  72]
#     @pdf.text_box "PO Box 97022", :at => [320,  60]
#     @pdf.text_box "Washington, DC 20090", :at => [320,  48]
    
#     address = @employer_profile.try(:organization).try(:office_locations).first.address 
#     @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x, 72]
#     if address
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.address_1}", :at => [address_x, 60]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.address_2}", :at => [address_x, 48]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 36]
#     end

#     #Add Amount Enclosed
#     ####################################################################################################################

#     @pdf.start_new_page

#     @pdf.move_down initialmove_y

#     @pdf.text_box "Payment Options", :at => [address_x, @pdf.cursor], :style => :bold, :align => :center
#     @pdf.move_down 24
#     @pdf.text_box "Make a secure online electronic check payment. Use the account number found at the top of your invoice to login at:", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 36
#     @pdf.text_box "https://www.e-BillExpress.com/ebpp/DCHealthPay/", :at => [address_x, @pdf.cursor], :align => :center
#     @pdf.move_down 24
#     @pdf.text_box "Return the attached payment coupon with a personal, business, or cashier’s check for prompt, accurate and timely posting of your payment. Address payments to:", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 36
#     @pdf.text_box "DC Health Link", :at => [220,  @pdf.cursor]
#     @pdf.move_down 16
#     @pdf.text_box "PO Box 97022", :at => [220,  @pdf.cursor]
#     @pdf.move_down 16
#     @pdf.text_box "Washington, DC 20090", :at => [220,  @pdf.cursor]
#     @pdf.move_down 24
#     @pdf.text_box "Call DC Health Link Customer Service at 855-532-5465", :at => [address_x, @pdf.cursor]
#     ##################################################################################################################

#     hbx_enrollments.each do |enrollment|
#       employee = enrollment.subscriber.person.employee_roles.try(:first).try(:census_employee)

#       @pdf.start_new_page
    
#       @pdf.move_down initialmove_y

#       @pdf.text_box "DC Health Link", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "PO Box 97022", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "Washington, DC 20090", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y

#       last_measured_y = @pdf.cursor
#       @pdf.move_cursor_to @pdf.bounds.height

#       @pdf.move_cursor_to last_measured_y
     
#       @pdf.move_down 155
#       last_measured_y = @pdf.cursor

#       @pdf.text_box "#{employee.full_name}", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{employee.address.address_1}", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{employee.address.address_2}", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{employee.address.city}, #{employee.address.state} #{employee.address.zip}", :at => [address_x,  @pdf.cursor]


#       @pdf.start_new_page
#       @pdf.move_down initialmove_y
#       last_measured_y = @pdf.cursor
#       @pdf.move_cursor_to @pdf.bounds.height

#       @pdf.text_box "Notice Date:", :at => [address_x, @pdf.cursor], :style => :bold

#       @pdf.move_down 48
#       @pdf.image logopath, :width => 150, :at => [address_x,  @pdf.cursor]
#       @pdf.move_down 72

#       @pdf.text_box "#{employee.full_name}", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{employee.address.address_1}", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{employee.address.address_2}", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{employee.address.city}, #{employee.address.state} #{employee.address.zip}", :at => [address_x,  @pdf.cursor]

#       @pdf.move_down 72
#       @pdf.text_box "Apple Health Insurance Status Update", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold
#       @pdf.move_down 48
#       @pdf.text_box "Dear #{employee.full_name},", :at => [address_x, @pdf.cursor]
#       @pdf.move_down 24
#       @pdf.text_box "This notice is to inform you that your health insurance provided by Apple, through DC Health Link may be canceled due to non-payment by your employer. If your employer does not pay in full by February 29, 2016, coverage will be canceled as of December 31, 2015. Please contact your employer with any questions or concerns regarding the status of their payment.", :at => [address_x, @pdf.cursor]
#       @pdf.move_down 72
#       @pdf.text_box "In the event that your employer-provided health insurance is canceled, you may be eligible for health benefits, including assistance with your premiums, through DC Health Link. If you are notified that your insurance is canceled, you will have 30 days to enroll in individual health coverage through the Individual DC Health Link. If you do not enroll promptly during this special enrollment period, you may have to wait until the next Open Enrollment period, at the end of 2016, to enroll.", :at => [address_x,  @pdf.cursor]
#       @pdf.move_down 96
#       @pdf.text_box "For additional information about your health insurance, you can access your DC Health Link account at www.DCHealthLink.com.", :at => [address_x, @pdf.cursor]
#     end

# #############################################################################################################
#     @pdf.start_new_page
    
#     @pdf.move_down initialmove_y

#     @pdf.text_box "DC Health Link", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y
#     @pdf.text_box "PO Box 97022", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y
#     @pdf.text_box "Washington, DC 20090", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y

#     last_measured_y = @pdf.cursor
#     @pdf.move_cursor_to @pdf.bounds.height

#     @pdf.move_cursor_to last_measured_y
   
#     @pdf.move_down 155
#     last_measured_y = @pdf.cursor

#     @pdf.text_box "Roman Regins", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y
#     @pdf.text_box "WWE", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y
#     @pdf.text_box "123 Main Street", :at => [address_x,  @pdf.cursor]
#     @pdf.move_down lineheight_y
#     @pdf.text_box "Washington, DC 20036", :at => [address_x,  @pdf.cursor]

# ##############################################################################################################

#     @pdf.start_new_page

#     @pdf.text_box "Notice Date: <xx>/15/<xxxx>", :at => [address_x, @pdf.cursor], :style => :bold

#     @pdf.move_down 36

#     @pdf.image logopath, :width => 150, :at => [address_x,  @pdf.cursor]

#     @pdf.move_down 72

#     dchbx_table_light_blue(late_payment_invoice_header_data, invoice_header_x)

#     address = @employer_profile.try(:organization).try(:office_locations).first.address 
#     @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x, 585]
#     if address
#       @pdf.text_box "#{address.address_1}", :at => [address_x, 573]
#       @pdf.text_box "#{address.address_2}", :at => [address_x, 561]
#       @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 549]
#     end

#     @pdf.move_down 36

#     @pdf.text_box "Second and Final Notice Prior to Termination", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold
#     @pdf.move_down 24
#     @pdf.text_box "Dear NAME,", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 24
#     @pdf.text_box "As of the date of this notice, our records indicate we have not yet received a full premium payment for <January> health care benefits though DC Health Link.", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 36
#     @pdf.text_box "Please pay your premium by <February 29, 2016> or health coverage for your employees will be canceled retroactively effective <December 31, 2015>.", :at => [address_x, @pdf.cursor], :style => :bold
#     @pdf.move_down 48
#     @pdf.text_box "If you have already sent your full premium payment, please disregard this notice.", :at => [address_x, @pdf.cursor], :align => :center
#     @pdf.move_down 24
#     @pdf.text_box "See reverse side for payment options.", :at => [address_x, @pdf.cursor], :align => :center, :style => :italic

#     @pdf.move_down 72

#     @pdf.text_box "PLEASE RETURN THE BOTTOM PORTION WITH YOUR PAYMENT", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold
#     @pdf.move_down 60

#     @pdf.image logopath, :width => 150, :at => [logo_x,  @pdf.cursor]

#     dchbx_table_light_blue(invoice_header_data,address_x)

#     @pdf.move_down 36
#     @pdf.text_box "Amount Enclosed:", :at => [address_x, 114], :align => :center, :style => :bold
#     @pdf.image cheque_amount_path, :width => 160, :at => [cheque_amount_path_x, @pdf.cursor]

#     @pdf.text_box "DC Health Link", :at => [320,  72]
#     @pdf.text_box "PO Box 97022", :at => [320,  60]
#     @pdf.text_box "Washington, DC 20090", :at => [320,  48]
 
#     address = @employer_profile.try(:organization).try(:office_locations).first.address 
#     @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x, 72]
#     if address
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.address_1}", :at => [address_x, 60]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.address_2}", :at => [address_x, 48]
#       @pdf.move_down lineheight_y
#       @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 36]
#     end

#     #Add Amount Enclosed
#     ####################################################################################################################

#     @pdf.start_new_page

#     @pdf.move_down initialmove_y

#     @pdf.text_box "Payment Options", :at => [address_x, @pdf.cursor], :style => :bold, :align => :center
#     @pdf.move_down 24
#     @pdf.text_box "Make a secure online electronic check payment. Use the account number found at the top of your invoice to login at:", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 36
#     @pdf.text_box "https://www.e-BillExpress.com/ebpp/DCHealthPay/", :at => [address_x, @pdf.cursor], :align => :center
#     @pdf.move_down 24
#     @pdf.text_box "Return the attached payment coupon with a personal, business, or cashier’s check for prompt, accurate and timely posting of your payment. Address payments to:", :at => [address_x, @pdf.cursor]
#     @pdf.move_down 36
#     @pdf.text_box "DC Health Link", :at => [220,  @pdf.cursor]
#     @pdf.move_down 16
#     @pdf.text_box "PO Box 97022", :at => [220,  @pdf.cursor]
#     @pdf.move_down 16
#     @pdf.text_box "Washington, DC 20090", :at => [220,  @pdf.cursor]
#     @pdf.move_down 24
#     @pdf.text_box "Call DC Health Link Customer Service at 855-532-5465", :at => [address_x, @pdf.cursor]
#     ##################################################################################################################


    @pdf
  end

end
