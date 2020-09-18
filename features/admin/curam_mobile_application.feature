Feature: If HBX Admin selects CURAM or Mobile application types, Experian Auth and Consent Page and Document Upload pages are bypassed

Scenario: If Applicant has e_case_id then EA will automatically populate the Application Type as CURAM
  Given Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And admin has navigated into the NEW CONSUMER APPLICATION
  And the user has a family with e_case_id and visit personal information edit page
  Then EA will automatically populate the Application Type as CURAM

Scenario: If Applicant dont have e_case_id then EA will automatically populate all Application Types.
  Given Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And admin has navigated into the NEW CONSUMER APPLICATION
  And the applicant with no e_case_id and visit personal information edit page
  And the Admin is on the Personal Info page for the family
  Then EA will display all the Application Types

Scenario: If the user selects the CURAM or Mobile application option then the user should navigate to the HOUSEHOLD INFO page.
  Given the FAA feature configuration is disabled
  And Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And admin has navigated into the NEW CONSUMER APPLICATION
  And the applicant with no e_case_id and visit personal information edit page
  And the Admin is on the Personal Info page for the family
  And the Admin clicks the Application Type drop down
  And the Admin selects the Curam application option
  And all other mandatory fields on the page have been populated
  When Admin clicks CONTINUE button
  Then the Admin should navigate to Household Info Page

Scenario: If the user selects the CURAM or Mobile application option then the user should navigate to the HOUSEHOLD INFO page.
  Given the FAA feature configuration is disabled
  And Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And admin has navigated into the NEW CONSUMER APPLICATION
  And the applicant with no e_case_id and visit personal information edit page
  And the Admin is on the Personal Info page for the family
  And the Admin clicks the Application Type drop down
  And the Admin selects the Mobile application option
  And all other mandatory fields on the page have been populated
  When Admin clicks CONTINUE button
  Then the Admin should navigate to Household Info Page

Scenario: If the user selects the CURAM or Mobile application option then the user should navigate to the HOUSEHOLD INFO page.
  Given the FAA feature configuration is enabled
  And Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And admin has navigated into the NEW CONSUMER APPLICATION
  And the applicant with no e_case_id and visit personal information edit page
  And the Admin is on the Personal Info page for the family
  And the Admin clicks the Application Type drop down
  And the Admin selects the Curam application option
  And all other mandatory fields on the page have been populated
  When Admin clicks CONTINUE button
  Then the Admin should be on the Help Paying for Coverage page

Scenario: If the user selects the CURAM or Mobile application option then the user should navigate to the HOUSEHOLD INFO page.
  Given the FAA feature configuration is enabled
  And Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And admin has navigated into the NEW CONSUMER APPLICATION
  And the applicant with no e_case_id and visit personal information edit page
  And the Admin is on the Personal Info page for the family
  And the Admin clicks the Application Type drop down
  And the Admin selects the Mobile application option
  And all other mandatory fields on the page have been populated
  When Admin clicks CONTINUE button
  Then the Admin should be on the Help Paying for Coverage page
