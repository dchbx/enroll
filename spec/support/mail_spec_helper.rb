module MailSpecHelper
  shared_context "MailSpecHelper" do
    def refresh_mailbox
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end

    def user_mailer_invitation_subject
      "Invitation from your Employer to Sign up for Health Insurance at #{Settings.site.short_name} "
    end

    def user_mailer_invitation_body(person_name)
      [person_name, "Your employer has created a Health Benefits Program through #{Settings.site.short_name}.",
       'Please visit',
       "to learn more about your benefits and sign up for insurance during open enrollment."]
    end

    def user_mailer_renewal_invitation_subject
      "Enroll Now: Your Health Plan Open Enrollment Period has Begun"
    end

    def user_mailer_renewal_invitation_body(census_employee)
      ["Dear #{census_employee.full_name}","Congratulations! #{census_employee.employer_profile.legal_name}, has chosen to renew the offer of health insurance coverage
  to its employees through #{Settings.site.short_name} and will contribute to the monthly premium to make the cost of coverage more affordable.",
       "You Are Able to Change Your Plan Selection during Open Enrollment"]
    end
  end
end
