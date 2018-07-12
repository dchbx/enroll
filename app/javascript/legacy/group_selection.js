function attachGroupSelectionHandlers() {
	if ($("#waiver_reasons_selection_modal_form").length) {
		$("#waiver_reasons_selection_modal_form").on( "submit", function( event ) {
			event.preventDefault();
			$("#is_waiving_hidden_value_field").val("true");
			$("#waiver_reason_hidden_value_field").val($("#waiver_reason_selection_dropdown").val());
			$("#group-selection-form").trigger("submit");
		});
	}
}

function InitGroupSelection() {
	$(window.document).ready(attachGroupSelectionHandlers);
}

module.exports = { InitGroupSelection: InitGroupSelection };