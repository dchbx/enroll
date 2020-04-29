function setupExternalRedirectedListener() {
  var changeElement = document.getElementById("external_app_redirection_data");
  if (changeElement != null) {
    var redirUrl = changeElement.getAttribute("data-redirect-url");
    var jwtVal = changeElement.getAttribute("data-redirect-jwt");
    if (redirUrl != null) {
      window.localStorage.setItem("jwt", jwtVal);
      window.location.assign(redirUrl);
    }
  }
}

document.addEventListener("DOMContentLoaded", function(event) { 
  setupExternalRedirectedListener();
});