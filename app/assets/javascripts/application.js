//= require libraries/jquery.js
//= require i18n
//= require i18n/translations
//= require bootstrap/bootstrap-alert
//= require bootstrap/bootstrap-transition
//= require bootstrap/bootstrap-dropdown
//= require bootstrap/bootstrap-tooltip
//= require bootstrap/bootstrap-tab
//= require bootstrap/bootstrap-modal
//= require_self
//= require_tree ./helpers/
//= require_tree ./application/

var Remotehue = {PAGES: {}, Helpers: {}};
Remotehue.initialize = function() {
    $(".tt").tooltip({animation: false, placement: "right", container: $("body")});
    $(".dropdown-toggle").dropdown();

    $(".contact_email").click(function() {
        mixpanel.track("Email Contact Clicked", {location: $(this).data("location")});
    });

    $(".alert .close").click(function() {
        var alert = $(this).closest(".alert");
        alert.slideUp("fast", function() { alert.remove(); });
    });
};