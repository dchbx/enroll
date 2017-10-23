Feature: Phone application feature

Background: phone application
	Given Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
	And admin has navigated into the NEW CONSUMER APPLICATION
	And the Admin is on the Personal Info page for the family
	And the Admin clicks the Application Type drop down
	And the Admin selects the Phone application option
	And all other mandatory fields on the page have been populated
	When Admin clicks CONTINUE button
	Then the Admin should navigate to the Experian Auth and Consent Page

Scenario: phone applicationfgdhfd fjhgdfg
	Given the Admin should navigate to the Experian Auth and Consent Page
	When the Admin chooses 'I Disagree'
	And Admin clicks CONTINUE button
	Then the Admin will be navigated to the DOCUMENT UPLOAD page

Scenario: phone applicationfgdhfd fjhgdfg
	Given the Admin should navigate to the Experian Auth and Consent Page
	When the Admin chooses 'I Disagree'
	And Admin clicks CONTINUE button
	Then the Admin will be navigated to the DOCUMENT UPLOAD page
	When the Admin clicks CONTINUE without uploading and verifying an application
	Then the Admin can not navigate to the next page

Scenario: phone applicationfgdhfd fjhgdfg
	Given the Admin should navigate to the Experian Auth and Consent Page
	When the Admin chooses 'I Disagree'
	And Admin clicks CONTINUE button
	Then the Admin will be navigated to the DOCUMENT UPLOAD page
	When the Admin clicks CONTINUE after uploading and verifying an application
	Then the Admin can navigate to the next page and finish the application

