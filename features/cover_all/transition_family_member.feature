Feature: can Transition family members

	Background: Hbx Admin can Transition family members
		Given a Hbx admin with hbx_staff role exists
		And a consumer exists
		And a Hbx admin logs on to Portal

	Scenario: Only Hbx Admin can view Transition family members link actions dropdown in families index page
		When Hbx Admin click Families link
		Then Hbx Admin should see the list of primary applicants and an Action button
		When Hbx Admin clicks Action button
		Then Hbx Admin should see an Transition family members link

	Scenario: Transition family member from consumer role to cover all
		When Hbx Admin click Families link
		Then Hbx Admin should see the list of primary applicants and an Action button
		When Hbx Admin clicks Action button
		Then Hbx Admin should see an Transition family members link
		When Hbx Admin clicks Transition family members link
		And Hbx Admin should see the form being rendered to transition each family members seperately
		And Hbx Admin enter/update information of each member individually
		And Hbx Admin clicks submit button
		And Hbx Admin should show the Transition Results and the close button
		When Hbx Admin clicks close button
		Then Transition family members form should be closed
