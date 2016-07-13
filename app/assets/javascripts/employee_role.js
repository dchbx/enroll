$(document).ready(function() {
	$('#new_person_wrapper #btn-continue').on('click', function() {
		if ( $('.select-employer input').is(':checked') ) {
			if ( $('.select-employer input:checked').hasClass('employer-sponsored') ) {
				var form_class = $('.select-employer input:checked').attr('id');
				$('form.'+form_class).submit();
			} else {
				$('.new_person:last').submit();
			}
		}
	});
});

function displayEmployeeRoleSearch() {
	$("#overlay").css("display", "none");
	$("a.name").css("padding-top", "30px");
	$(".disable-btn").css("display", "inline-block");
	$('.sidebar a:first').addClass('style_s_link');
	$(".start").hide();
}

function check_personal_info_exists()
{
	var check = $('#personal_info input[required]').filter(function() { return this.value == ""; });
	return check;
}

function check_dependent_info_exists()
{
	var check = $('#new_family_member input[required]').filter(function() { return this.value == ""; });
	return check;
}

function match_person()
{
	gender_checked = $("#person_gender_male").prop("checked") || $("#person_gender_female").prop("checked");

	if(check_personal_info_exists().length==0 && gender_checked)
	{
		$('.employers-row').html("");
		$('#personal_info .employee-info').removeClass('require-field');

		$.ajax({
			type: "POST",
			url: "/people/match_person.json",
			data: $('#new_person').serialize(),
			success: function (result) {
				// result.person gives person info to populate
				if(result.matched == true)
		{
			person = result.person;
			$("#people_id").val(person._id);
			_getEmployers();

		}
				else
		{
			$('.search_results').removeClass('hidden');
			$('.employers-row').html("");
			$('.fail-search').removeClass('hidden');
		}

		//Sidebar Switch - Search Active
				$(".overlay-in").css("display", "block");
			}
		});
	} else {
		$('#personal_info .employee-info').addClass('require-field');
	}
}


function getAllEmployers()
{
	$.ajax({
		type: "GET",
	data:{id: $("#people_id").val()},
	url: "/people/get_employer.js",
	});
}

function side_bar_link_style()
{
	$('.sidebar a').removeClass('style_s_link');
	$('.sidebar a.address_info').addClass('style_s_link');
}

function _getEmployers()
{
	side_bar_link_style();

	getAllEmployers();
}

$(function () {
	displayEmployeeRoleSearch();

	/* Match Person */
	$('#search-employer').click(function() {
		match_person();
	});
});

$(document).on('change', '.terminate_confirm select#terminate_reason', function() {
  if($(this).val() == undefined || $(this).val() == ""){
    $(this).parents('.terminate_confirm').find('.terminate_reason_submit').attr("disabled",true);
  }else{
    $(this).parents('.terminate_confirm').find('.terminate_reason_submit').attr("disabled",false);
  }
});
