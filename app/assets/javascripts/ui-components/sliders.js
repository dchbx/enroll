//Sliders

function updateSlider(element) {
  var id = element.id;
  var slider = id.replace('-box','')
  var value = $('#'+id).val();
  $('#'+slider).val(value);
}

function updateSliderBox(element) {
  var id = element.id;
  var value = $('#'+id).val()
  $('#'+id+'-box').val(value)
}