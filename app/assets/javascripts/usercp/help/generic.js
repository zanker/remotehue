Remotehue.PAGES["usercp/help/ifttt"] = function() {
    var scope = $("#step1").closest(".row");
    var next_step = $("#next-step");
    var step = next_step.data("step-start");
    var last_step = scope.find(".step-guide li:last").data("step");

    if( window.location.hash.match(/^#step/) ) {
        step = parseInt(window.location.hash.replace("#step", ""));
        if( $("#step" + step).length == 0 ) {
            step = next_step.data("step-start");
        }
    }

    var guides = scope.find(".step-guide li");
    var initial = true;
    function change_step(new_step) {
        if( !initial ) {
            $("#step" + new_step).slideDown("fast");
            $("#step" + step).slideUp("fast");
        } else if( new_step != 1 ) {
            $("#step" + new_step).show();
            $("#step1").hide();
            initial = null;
        }

        guides.removeClass("active");
        scope.find(".step-guide li[data-step=" + new_step + "]").addClass("active");

        step = new_step;
        window.location.hash = "#step" + step;

        $("#previous-step")[step == 1 ? "hide" : "show"]();
        $("#next-step")[step == last_step ? "hide" : "show"]();
    }

    next_step.click(function(event) {
        event.preventDefault();
        change_step(step + 1);
    });

    $("#previous-step").click(function(event) {
        event.preventDefault();
        change_step(step - 1);
    });

    scope.find(".step-guide li a").click(function(event) {
        event.preventDefault();
        change_step($(this).closest("li").data("step"));
    });

    // Setup the current visible step
    change_step(step);
}