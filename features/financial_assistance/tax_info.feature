Feature: A dedicated page that gives the user access to Tax Info page for a given applicant as well as Financial application forms for each household member.

Background: User can edit tax info page for a household member
  Given a plan year, with premium tables, exists
	Given that the user is on the FAA Household Info page
	And the applicant has no saved data
	When the user clicks the ADD Info Button for a given household member
	Then the user will navigate to the Tax Info page for the corresponding applicant.

Scenario: Cannot continue from tax info page without form completely filled
	Given the user is editing an application for financial assistance
	When the user navigates to the Tax Info page for a given applicant
	And Will this person file taxes for <system year>? has a nil value stored
	And Will this person be claimed as a tax dependent for <system year>? has a nil value stored
	Then the CONTINUE will be visibly disabled
	And should not be actionable.

Scenario: Cannot continue from tax info page without tax dependent status filled
	Given the user is editing an application for financial assistance
	When the user navigates to the Tax Info page for a given applicant
	And Will this person file taxes for <system year>? does not have a nil value stored
	And Will this person be claimed as a tax dependent for <system year>? has a nil value stored
	Then the CONTINUE will be visibly disabled
	And should not be actionable.

Scenario: Can continue from tax info page when form filled
	Given the user is editing an application for financial assistance
	When the user navigates to the Tax Info page for a given applicant
	And Will this person file taxes for <system year>? does not have a nil value stored
	And Will this person be claimed as a tax dependent for <system year>? does not have a nil value stored
	Then the CONTINUE will be visibly enabled
	And should be actionable.

Scenario: Can continue from tax info page when form filled
	Given the user is on the Tax Info page for a given applicant
	And Will this person file taxes for <system year>? does not have a nil value stored
	And Will this person be claimed as a tax dependent for <system year>? does not have a nil value stored
	When the user clicks on the CONTINUE button
	Then the user will navigate to the Job Income page for the same applicant.

Scenario: Confirmation pop-up functionality
  When the user clicks the BACK TO ALL HOUSEHOLD MEMBERS link
  Then a modal should show asking the user are you sure you want to leave this page

Scenario: Can choose primary applicant claiming dependent from dropdown
  Given a plan year, with premium tables, exists
  When the user navigates to the Tax Info page for a given applicant
  And primary applicant completes application and marks they are required to file taxes
  When user clicks CONTINUE
  When user clicks CONTINUE
  When user clicks CONTINUE
  And the user fills out the review and submit details
  Given the user is on the Tax Info page for a dependent applicant
  And the user indicates that the dependent will be claimed as a tax dependent by primary applicant
  Then the CONTINUE will be visibly enabled
  And should be actionable.
  When the user clicks on the CONTINUE button
  And the dependent should now be claimed by the primary dependent
