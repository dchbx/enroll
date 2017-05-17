require 'rails_helper'

RSpec.describe Importers::ConversionEmployeeCreate, type: :model do
  let (:required_fields)  { [] }
  let (:optional_fields)  { [] }

  describe "syntax validation" do
    context "unable to recognize file as CSV or Excel" do
    end

    context "import file is empty" do
    end

    context "file has content" do
      context "and the first row is a header row" do
      end

      context "and the first row is a data row" do
        context "and row has incorrect number of cells" do
          it "adds a 'invalid record format' error to the instance"
          it "adds the error to the instance's error[:base] array"
        end

        context "and row has correct number of cells" do
          context "and a required field is nil" do
              it "adds a 'nil required field' error to the instance"
              it "adds the error to the instance's error[:base] array"
          end

          context "and all required fields have values" do
            context "and a required field fails to parse" do
              it "adds a 'required field parse failure' error to the instance"
              it "adds the error to the instance's error[:base] array"
            end

            context "and all required fields successfully parse" do
              context "and an optional field fails to parse" do
                it "adds a 'optional field parse failure' error to the instance"
                it "sets the optional field value to nil"
              end

              context "and all fields successfully parse" do
                it "the record instance should be valid"
              end
            end
          end
        end

      end
    end
  end

  describe "functional validation at the record level" do
    context "an employee without dependents is added" do
      context "and the referenced employer is not found" do
        it "adds an 'employer not found' error"
        it "adds the error to the instance's error[:base] array"
      end

      context "and the referenced employer is found" do

        context "and the employee date of birth is in the future" do
          it "adds an 'employee date of birth in the future not allowed' error"
          it "adds the error to the instance's error[:base] array"
        end

        context "and the hire date is in the future" do
          it "adds an 'employee hire date in the future not allowed' error"
          it "adds the error to the instance's error[:base] array"
        end

        context "and the benefit begin date is in the future" do
          it "adds an 'benefit begin date in the future not allowed' error"
          it "adds the error to the instance's error[:base] array"
        end

      end
    end

    describe "an employee with dependents is added" do
      it "should add the employee and dependents"
    end

  end

end
