Feature: A dedicated page that gives the user access to household member creation/edit as well as Financial application forms for each household member.

Background: new applicant navigation to the FAA Household Info page
	Given that the user is applying for a CONSUMER role
  And the primary member has supplied mandatory information required
  And the primary member authorizes the system to call EXPERIAN
  And system receives a positive response from EXPERIAN
  And the user answers all VERIFY IDENTITY  questions
  When the user clicks submit
  And Experian returns a VERIFIED response
  Then the user will navigate to the Help Paying for Coverage page
	And saves a YES answer to the question: Do you want to apply for Medicaid…

Scenario: new applicant navigation to the FAA Household Info page
  Given that the user is on the Application Checklist page
  When the user clicks CONTINUE
  Then the user will navigate to the FAA Household Infor: Family Members page
