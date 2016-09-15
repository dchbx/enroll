var CensusMember = (function (window){
  function appendDependentQuestions(e){
  var option = $(e).closest("fieldset").find("#employee_relationship").val();
   var dependent_list = [ "child","child_under_26","child_26_and_over" ,"nephew_or_niece", "grandchild"];
   // get age from DOB
   var dob = $(e).closest("fieldset").find(".dob-picker");
    if(dob != null && dob.val() != null){
       var age = getAge(dob.val());
       if($.inArray(option,dependent_list) != -1 ){
        $(e).closest("fieldset").find("#primary_caregiver").removeClass("hidden_field");
         if(age > 18 ){
          $(e).closest("fieldset").find("#dependent_disabled").removeClass("hidden_field");
         }else if(!$$(e).closest("fieldset").find("#dependent_disabled").hasClass("hidden_field")){
          $(e).closest("fieldset").find("#dependent_disabled").addClass("hidden_field");
         }
      }else if(!$(e).closest("fieldset").find("#primary_caregiver").hasClass("hidden_field")){
        $(e).closest("fieldset").find("#primary_caregiver").removeClass("hidden_field");
      }
    }
  }

  function getAge(dob){
    // var date_parts= dob.split(dob,"/");
    var dob = new Date(dob);
    var today = new Date();
    var age = Math.floor((today-dob) / (365.25 * 24 * 60 * 60 * 1000));
    return age;
  }

  return {
    appendDependentQuestions : appendDependentQuestions
  }
})(window);