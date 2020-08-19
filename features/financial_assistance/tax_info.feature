Feature: A dedicated page that gives the user access to Tax Info page for a given applicant as well as Financial application forms for each household member.

Background:
	Given that the user is on the FAA Household Info page
	And the applicant has no saved data
	When the user clicks the ADD Info Button for a given household member
	Then the user will navigate to the Tax Info page for the corresponding applicant.

Scenario:
	Given the user is editing an application for financial assistance
	When the user navigates to the Tax Info page for a given applicant
	And Will this person file taxes for <system year>? has a nil value stored
	And Will this person be claimed as a tax dependent for <system year>? has a nil value stored
	Then the CONTINUE will be visibly disabled
	And should not be actionable.

Scenario:
	Given the user is editing an application for financial assistance
	When the user navigates to the Tax Info page for a given applicant
	And Will this person file taxes for <system year>? does not have a nil value stored
	And Will this person be claimed as a tax dependent for <system year>? has a nil value stored
	Then the CONTINUE will be visibly disabled
	And should not be actionable.

Scenario:
	Given the user is editing an application for financial assistance
	When the user navigates to the Tax Info page for a given applicant
	And Will this person file taxes for <system year>? does not have a nil value stored
	And Will this person be claimed as a tax dependent for <system year>? does not have a nil value stored
	Then the CONTINUE will be visibly enabled
	And should be actionable.

Scenario:
	Given the user is on the Tax Info page for a given applicant
	And Will this person file taxes for <system year>? does not have a nil value stored
	And Will this person be claimed as a tax dependent for <system year>? does not have a nil value stored
	When the user clicks on the CONTINUE button
	Then the user will navigate to the Job Income page for the same applicant.

Scenario: Confirmation pop-up functionality
  When the user clicks the BACK TO ALL HOUSEHOLD MEMBERS link
  Then a modal should show asking the user are you sure you want to leave this page
