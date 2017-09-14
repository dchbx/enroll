Feature:	A dedicated page that improves visibility & ensures that the user is making an educated election.
Background:
  Given that the user is applying for a CONSUMER role
  And the primary member has supplied mandatory information required
  And the primary member authorizes the system to call EXPERIAN
  And system receives a positive response from EXPERIAN

Scenario:	Primary Member Passes Experian Validation
  Given the user answers all VERIFY IDENTITY  questions
  When the user clicks submit
  And Experian returns a VERIFIED response
  Then The user will navigate to the Help Paying for Coverage page

Scenario: User navigates forward without answering mandatory question
  Given the user is on the Help Paying For Coverage page
  When the user clicks CONTINUE
  And the answer to Do you want to apply for Medicaid… is NIL
  Then the user will remain on the page
  And an error message will display stating the requirement to populate an answer

Scenario:	User does NOT want to apply for financial assistance
  Given the user is on the Help Paying For Coverage page
  When the answer to Do you want to apply for Medicaid… is NO
  And the user clicks CONTINUE
  Then the user will navigate to the UQHP Household Info: Family Members page

Scenario: User wants to apply for financial assistance
  Given	the user is on the Help Paying For Coverage page
  When the answer to Do you want to apply for Medicaid… is YES
  And the user clicks CONTINUE
  Then the user will navigate to the FAA Household Info: Family Members page

Scenario: User clicks PREVIOUS or the BACK browser button
  Given	the user is on the Help Paying For Coverage page
  When the answer to Do you want to apply for Medicaid… is YES
  And the user clicks CONTINUE
  And the user clicks the PREVIOUS link
  And the user is on the Help Paying For Coverage page

Scenario: User clicks Save & Exit
  Given the user is on the Help Paying For Coverage page
  When the user clicks the SAVE & EXIT link
  And successfully logs out
  Then next time the user logs in and the user will be on Help Paying For Coverage page
  And an flash message will display stating Signed in sucessfully.
