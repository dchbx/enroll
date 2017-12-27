Feature: Hbx Admin as Phone Application for new consumer application

Background: Hbx Admin navigates into the new consumer application with In Person application option and goes forward till DOCUMENT UPLOAD page
  Given Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And admin has navigated into the NEW CONSUMER APPLICATION
  And the Admin is on the Personal Info page for the family
  And the Admin clicks the Application Type drop down
  And the Admin selects the In Person application option
  And all other mandatory fields on the page have been populated
  When Admin clicks CONTINUE button
  Then the Admin will be navigated to the DOCUMENT UPLOAD page

Scenario: Hbx Admin clicks continue without uploading and verifying an application
  Given the Admin will be navigated to the DOCUMENT UPLOAD page
  When the Admin clicks CONTINUE without uploading and verifying an Identity
  Then the Admin can navigate to the next page and finish the application
