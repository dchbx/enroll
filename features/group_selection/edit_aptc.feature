Feature: Edit APTC button

Background:
  Given a consumer exists
  And the consumer is logged in
  And consumer has a dependent in child relationship with age greater than 26
  And consumer has a dependent in spouse relationship with age greater than 26
  And consumer also has a health enrollment with primary person covered
  And the family has an active tax household
  When consumer visits home page after successful ridp

Scenario Outline: Edit APTC button is available for non-catastrophic plan
  And the metal level is <metal_level>
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the edit plan button
  Then consumer should see the edit plan page
  Then the Edit APTC button should be available

  Examples:
    | metal_level |
    | platinum |
    | silver |
    | gold |
    | bronze |

Scenario: Edit APTC button is not available for catastrophic plans
  And the metal level is catastrophic
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the edit plan button
  Then consumer should see the edit plan page
  Then the Edit APTC button should NOT be available

Scenario Outline: Edit APTC button is available for all HIOS ID endings
  Given the enrollment has HIOS ID ending in <id_number>
  And the metal level is gold
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the edit plan button
  Then consumer should see the edit plan page
  Then the Edit APTC button should be available

  Examples:
    | id_number |
    | "01" |
    | "02" |
    | "03" |
    | "04" |
    | "05" |
    | "06" |

# Scenario: Edit APTC button is available for IVL market
#  And the tax household has at least one member that is APTC eligible
#  When consumer clicks on the edit plan button
#  Then consumer should see the edit plan page
#  Then the Edit APTC button should be available

Scenario: Edit APTC button is not available for families with no members that are APTC eligible
  And the tax household has no members that are APTC eligible
  When consumer clicks on the edit plan button
  Then consumer should see the edit plan page
  Then the Edit APTC button should NOT be available

Scenario: Edit APTC button is not available for Resident
  Given the coverall enrollment flag is TRUE
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the edit plan button
  Then consumer should see the edit plan page
  Then the Edit APTC button should NOT be available

Scenario: Edit APTC button is available for Health Plans
  Given the enrollment is a Health plan
  And the metal level is gold
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the edit plan button
  Then consumer should see the edit plan page
  Then the Edit APTC button should be available

Scenario: Edit APTC button is not available for Dental Plans
  Given the enrollment is a Dental plan
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the edit plan button
  Then consumer should see the edit plan page
  Then the Edit APTC button should NOT be available

Scenario: Edit APTC button is available for families with at least 1 member that is APTC eligible
  And the tax household has at least one member that is APTC eligible
  When consumer clicks on the edit plan button
  Then consumer should see the edit plan page
  Then the Edit APTC button should be available

