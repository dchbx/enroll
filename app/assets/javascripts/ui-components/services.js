response = new Object();

function httpRequest(type,url,dataType,data) {
  
  var xhr = new XMLHttpRequest();
  
  switch (type) {
    case "GET":
      xhr.open('GET',url,true);
    break;
    case "POST":
      xhr.open('POST',url,dataType,data)
    break;
    case "PUT":
      xhr.open('PUT',url,dataType,data)
    break;
    case "DELETE":
      xhr.open('DELETE',url,dataType,data)
    break;
  }
  //xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.onload = function() {
      if (this.status === 200) {
          console.log(this.responseText)
      }
  }
}