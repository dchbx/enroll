var KpPaymentRedirection = (function(){
    var saml_response;

    // update payload every time when user clicks on PayNow button
    function responseData(data){
        saml_response = data.SAMLResponse;
    }

    // generate payment data
    function generatePaymentData(){
        var element = $('#kp-pay-now');
        var enrollment = element.attr("data-enrollment");
        $.ajax({
            type: "GET",
            url: "/payment_transactions/generate_saml_response",
            data: {enrollment_id: enrollment},
            success: function(data, textStatus, jqXHR){
                // check if data generated
                validateRedirectionRequest(data);
            }
        });
    }

    function validateRedirectionRequest(data){
        if (data.SAMLResponse ) {
            // update payload variable
            responseData(data);
        } else {
            // error message
            var $payNowModal = $('#payNowModal');
            var noPayloadError = document.createElement('div');
            noPayloadError.classList.add('alert', 'alert-danger');
            noPayloadError.innerText = "Error. Payment data can't be generated";
            $payNowModal.modal('hide');
            $payNowModal.siblings().first().prepend(noPayloadError);
        }
    }

    function paymentRedirectionRequest(){
        $('#payNowModal').modal('hide');
        if (saml_response){
            $.ajax({
                type: "POST",
                url: "/saml/redirection_test",
                data: {"SAMLResponse": saml_response},
                success: function(data, textStatus, jqXHR){
                    // function to only represents the payment redirection data for TEST
                    // DELETE before PRODUCTION Release!!!
                    showPaymentDataTest(data);
                },
                error: function(jqXHR, textStatus, errorThrown){
                    //error handler
                }
            });
        } else {
            generatePaymentData();
        }
    }

    // function to only represents the payment redirection data for TEST
    // DELETE before PRODUCTION Release!!!
    function formatXml(xml) {
        var formatted = '';
        var reg = /(>)(<)(\/*)/g;
        xml = xml.replace(reg, '$1\r\n$2$3');
        var pad = 0;
        jQuery.each(xml.split('\r\n'), function(index, node) {
            var indent = 0;
            if (node.match( /.+<\/\w[^>]*>$/ )) {
                indent = 0;
            } else if (node.match( /^<\/\w/ )) {
                if (pad != 0) {
                    pad -= 1;
                }
            } else if (node.match( /^<\w[^>]*[^\/]>.*$/ )) {
                indent = 1;
            } else {
                indent = 0;
            }

            var padding = '';
            for (var i = 0; i < pad; i++) {
                padding += '  ';
            }

            formatted += padding + node + '\r\n';
            pad += indent;
        });

        return formatted;
    }

    // function to only represents the payment redirection data for TEST
    // DELETE before PRODUCTION Release!!!
    function showPaymentDataTest(data) {
        var mydiv = document.createElement('div');
        var head = document.createElement('h1');
        var head2 = document.createElement('h2');
        var $pcont = $('#payment-payload-container');
        xml_raw = data.SAMLresponse;
        xml_formatted = formatXml(xml_raw);
        xml_escaped = xml_formatted.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/ /g, '&nbsp;').replace(/\n/g,'<br />');
        head.innerText = "SAML Request";
        head2.innerText = "This is the SAML payment request generated to send to the carrier.";
        mydiv.innerHTML = xml_escaped;
        $pcont.prepend(head2);
        $pcont.prepend(head);
        $('#payment-redirection-test-payload').append(mydiv);
    }

    return {
        generate_payment_data: generatePaymentData,
        validate_payload: validateRedirectionRequest,
        payment_redirection_request: paymentRedirectionRequest

    }

})();

$(document).ready(function(){
    // ajax call to genarate transaction record and saml payment data
    $('#kp-pay-now').on('click', KpPaymentRedirection.generate_payment_data);
    // send SAML request and IdP, we act as SP that sends SAML response
    $('#payment-redirect-kp').on('click', KpPaymentRedirection.payment_redirection_request);
});