function setupExternalRedirectedListener() {
  console.log('setupExternalRedirectedListener');
  var changeElement = document.getElementById("external_app_redirection_data");
  console.log(changeElement)
  if (changeElement != null) {
    var redirUrl = changeElement.getAttribute("data-redirect-url");
    var jwtVal = changeElement.getAttribute("data-redirect-jwt");
    if (redirUrl != null) {
      window.localStorage.setItem("jwt", jwtVal);
      window.location.assign(redirUrl + "?auth_token=" + jwtVal);
    }
  }
}

document.addEventListener("DOMContentLoaded", function(event) {
  setupExternalRedirectedListener();
});
