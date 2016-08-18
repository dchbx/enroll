@WIP
Feature: search IVL enrollment for SEP information

	As an HBX admin, I want to be able to search an IVL enrollment for SEP information. I should be able
	to filter the results of the requests based on the registration staus of the primary subscriber.

	Background:
		Given I have logged in as an HBX-Admin
		And I click the SEP link from the Admin DC Health Link login page

	Scenario: successfully navigate to SEP page
		Then the SEP page is displayed
		#assert default text in search box is "Name, SSN"
		And a search box is displayed where I can search by name or ssn
		And the ALL, IVL and EE tabs appear above the display list
		And I see columns with headings HBX ID, Last Name, First Name, SSN, Consumer and Employee
		And I see the Add SEP and History links

	#TODO create scenario to verify social security number appears in the form xxx-xx-1111


	Scenario: successfully view history page
		When I click the history link
		Then I see SEP History

	Scenario: primary subscriber is registered only as a consumer
		Given I have a primary subscriber who is registered only as a consumer
		When I click the IVL tab
		Then I see Yes in the Consumer Field and No in the Employee field for his search results

	Scenario: primary subscriber is registered only as an employee

		Given I have a primary subscriber who is only registered as an employee
		When I click the EE tab
		Then I see No in the Consumer Field and Yes in the Employee field for his search results

	Scenario: primary subscriber is registered as both a consumer and as an employee
		Given I have a primary subscriber who is registered as a consumer and as an employee
		When I click the All tab
		Then I see Yes in the Consumer Field and Yes in the Employee field for his search results
		When I click the IVL tab
		Then I see Yes in the Consumer Field and Yes in the Employee field for his search results
		When I click the EE tab
		Then I see Yes in the Consumer Field and Yes in the Employee field for his search results

	#TODO
	#Scenario Outline: filter SEP dashboard results using the filter buttons

		#Filtering through the search resultes when all 3 possible registration types exist

		#Given there are 2 consumer only subscribers, 3 employee only subscribers and 3 both subscribers in the system
		#When I push the <Button> button
		#Then I should see <Consumers> consumers only,  <Employee> employees only and <Both> both subscribers
		#Examples:
			#Filtering through the search resultes when all 3 types exist

			#| Button | Consumers | Employee | Both |
			#|   IVL	 |     2		 |     0		|   0	 |
			#| 	EE 	 |     0     |     3	  |   0  |
			#|   All  |     0     |     0    |   3  |
