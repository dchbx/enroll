@screenshots
Feature: SEP should not be prompted every time the user shops for a new plan
	
	Scenario: Users should only have to attest to meeting SEP criteria one time

	  Given a user exists
	  And the user signs in
	  And has already enrolled for SEP
	  When the user goes to the families homepage
	  And the user clicks Shop for plans button
	  Then the user should be able to use their existing SEP
