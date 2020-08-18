Feature: Change Tax Credit button

Background:
  Given a consumer exists
  And the consumer is logged in
  And consumer has a dependent in child relationship with age greater than 26
  And consumer has a dependent in spouse relationship with age greater than 26
  And consumer also has a health enrollment with primary person covered
  And the family has an active tax household
  And consumer has successful ridp
  When consumer visits home page

Scenario Outline: Change Tax Credit button is available for non-catastrophic plan
  And the metal level is <metal_level>
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the make changes button
  Then the Change Tax Credit button should be available

  Examples:
    | metal_level |
    | gold |
    | silver |
    | platinum |
    | bronze |

Scenario: Change Tax Credit button is not available for catastrophic plans
  And the metal level is catastrophic
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the make changes button
  Then consumer should see the make changes page
  Then the Change Tax Credit button should NOT be available

Scenario Outline: Change Tax Credit button is available for all HIOS ID endings
  Given the enrollment has HIOS ID ending in <id_number>
  And the metal level is gold
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the make changes button
  Then consumer should see the make changes page
  Then the Change Tax Credit button should be available

  Examples:
    | id_number |
    | "01" |
    | "02" |
    | "03" |
    | "04" |
    | "05" |
    | "06" |

# Scenario: Change Tax Credit button is available for IVL market
#  And the tax household has at least one member that is APTC eligible
#  When consumer clicks on the make changes button
#  Then consumer should see the make changes page
#  Then the Change Tax Credit button should be available

Scenario: Change Tax Credit button is not available for families with no members that are APTC eligible
  And the tax household has no members that are APTC eligible
  When consumer clicks on the make changes button
  Then consumer should see the make changes page
  Then the Change Tax Credit button should NOT be available

Scenario: Change Tax Credit button is not available for Resident
  Given the coverall enrollment flag is TRUE
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the make changes button
  Then consumer should see the make changes page
  Then the Change Tax Credit button should NOT be available

Scenario: Change Tax Credit button is available for Health Plans
  Given the enrollment is a Health plan
  And the metal level is gold
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the make changes button
  Then consumer should see the make changes page
  Then the Change Tax Credit button should be available

Scenario: Change Tax Credit button is not available for Dental Plans
  Given the enrollment is a Dental plan
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the make changes button
  Then consumer should see the make changes page
  Then the Change Tax Credit button should NOT be available

Scenario: Change Tax Credit button is available for families with at least 1 member that is APTC eligible
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the make changes button
  Then consumer should see the make changes page
  And the Change Tax Credit button should be available
  When the user clicks on the Change Tax Credit button
  And the user sees the Change Tax Credit Form

Scenario: Eligible IVL Family can Modify APTC
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the make changes button
  Then consumer should see the make changes page
  And the Change Tax Credit button should be available
  When the user clicks on the Change Tax Credit button
  And the user sees the Change Tax Credit Form
  And the user confirms "Yes" to change the tax credit
  And the user changes Tax credit applied to 50%
  When the user submits the Change Tax Credit form
  Then the user should see a message that their Tax Credits were updated
  And current user visits the family home page
  When consumer clicks on the make changes button
  When the user clicks on the Change Tax Credit button
  Then the user should see that applied tax credit has been set accordingly


