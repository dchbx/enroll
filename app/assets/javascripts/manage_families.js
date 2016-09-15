var ManageFamilies = (function (window){
  function appendDependentQuestions(){
  var option = $("#dependent_relationship").val();
   var dependent_list = [ "child" ,"nephew_or_niece", "grandchild"];
   // get age from DOB
   var dob = $("#family_member_dob_");
    if(dob != null && dob.val() != null){
       var age = getAge(dob.val());
       if($.inArray(option,dependent_list) != -1 ){
        $("#primary_caregiver").removeClass("hidden_field");
         if(age > 18 ){
          $("#dependent_disabled").removeClass("hidden_field");
         }else if(!$("#dependent_disabled").hasClass("hidden_field")){
          $("#dependent_disabled").addClass("hidden_field");
         }
      }else if(!$("#primary_caregiver").hasClass("hidden_field")){
        $("#primary_caregiver").removeClass("hidden_field");
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