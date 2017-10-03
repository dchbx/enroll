Feature: A dedicated page that gives the user access to Tax Info page for a given applicant as well as Financial application forms for each household member.

Background: Left Nav - navigation to Tax Info
	Given that the user is on the FAA Household Info page
	When the user clicks Add/Edit Info button for a given household member
	Then the user will navigate to the Tax Info page for the corresponding applicant.

Scenario: Left Nav Links - navigation to My Household section
	Given that the user is on the Tax Info page for a given applicant
	When the user clicks My Household section on the left navigation
	Then the user will navigate to the FAA Household Info page for the corresponding application.


Scenario: Left Nav Links - navigation to Income & Coverage section
	Given that the user is on the Tax Info page for a given applicant
	When the user clicks Income & Coverage section on the left navigation
	Then the cursor will display disabled.

Scenario: Left Nav Links - navigation to Tax Info section
	Given that the user is on the Tax Info page for a given applicant
	When the user clicks Tax Info section on the left navigation
	Then the cursor will display disabled.

Scenario: Left Nav Links - navigation to Job Income section
	Given that the user is on the Tax Info page for a given applicant
	When the user clicks Job Income section on the left navigation
	Then the user will navigate to the Job Income page for the corresponding applicant

Scenario: Left Nav Links - navigation to Other Income section
	Given that the user is on the Tax Info page for a given applicant
	When the user clicks Other Income section on the left navigation
	Then the user will navigate to the Other Income page for the corresponding applicant.

Scenario: Left Nav Links - navigation to Income Adjustments section
	Given that the user is on the Tax Info page for a given applicant
	When the user clicks Income Adjustments section on the left navigation
	Then the user will navigate to the Income Adjustments page for the corresponding applicant

Scenario: Left Nav Links - navigation to Health Coverage section
	Given that the user is on the Tax Info page for a given applicant
	When the user clicks Health Coverage section on the left navigation
	Then the user will navigate to the Health Coverage page for the corresponding applicant

Scenario: Left Nav Links - navigation to Other Questions section
	Given that the user is on the Tax Info page for a given applicant
	When the user clicks Other Questions section on the left navigation
	Then the user will navigate to the Other Questions page for the corresponding applicant
	