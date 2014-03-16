Remotehue.PAGES["usercp/schedules/edit"] = Remotehue.PAGES["usercp/schedules/new"] = function() {
    if( $("#hlc").length == 1 ) $("#hlc").modal();


    var max_triggers = $("#trigger-limit").data("limit");
    $("#schedule_trigger_ids").change(function() {
        var val = $(this).val();
        var total = val ? val.length : 0;
        if( total == max_triggers ) {
            $("#trigger-desc").hide();
            $("#trigger-limit").show();
        } else {
            $("#trigger-limit").hide();
            $("#trigger-desc").show();
        }
    }).trigger("change");

    $("#schedule_days .toggle-all input").change(function() {
      var checked = $(this).is(":checked");
      $("#schedule_days .day input").prop("checked", checked);
    });

    // Keep the current time in sync
    var time_offset = $("#current-time").data("time-offset") * 1000;
    var time_format = $("#current-time").data("time-format");
    var time_label = $("#current-time p");
    time_label.html(time_label.html().replace("[[time]]", "<strong></strong> <strong>" + $("#current-time").data("time-zone") + "</strong>"));
    time_label = time_label.find("strong:first");

    var js_time_offset = (new Date()).getTimezoneOffset() * 60 * 1000;
    time_offset += js_time_offset;
    function update_time() {
        var now = time_offset == 0 ? new Date : new Date(Date.now() + time_offset);
        time_label.text(I18n.strftime(now, time_format));
    }

    setInterval(update_time, 1000);
    update_time();

    // Sunrise/Sunset management
    if( $("#set-location").length == 0 ) {
        $("#sunrise .time, #sunset .time").each(function() {
            var label = $(this).find("p");
            label.html(label.html().replace("[[time]]", "<strong>" + $(this).data("time") + "</strong>"));
        });
    } else {
        function setup_location_form() {
            // Showing sunrise/sunset times of the location
            Remotehue.Helpers.Location.setup({url: $("#set-location .modal").data("solar-url"), text: $("#solar-time").data("text"), label:  $("#solar-time span"), loading: $("#solar-time img")})

            $("#set-location").submit(function(event) {
                event.preventDefault();

                $(this).find("input[type='submit']").button("loading");

                var center = Remotehue.Helpers.Location.map.getCenter();
                $.ajax($(this).attr("action"), {
                    type: "PUT",
                    data: {latitude: center.lat(), longitude: center.lng()},
                    success: function(res) {
                        $("#sunrise, #sunset").find(".warning").slideUp("fast");
                        $("#sunrise, #sunset").find(".fields").slideDown("fast");

                        var label = $("#sunrise .time").find("p")
                        label.html(label.html().replace("[[time]]", "<strong>" + res.sunrise + " " + res.timezone + "</strong>"));

                        label = $("#sunset .time").find("p")
                        label.html(label.html().replace("[[time]]", "<strong>" + res.sunset + " " + res.timezone + "</strong>"));

                        $("#set-location .modal").modal("hide");
                    }
                });
            });
        }
    }

    // Form handling
    var scope = $("#usercp_schedules_edit, #usercp_schedules_new").find("form:first");
    scope.submit(function(event) {
        event.preventDefault();

        Remotehue.Helpers.Errors.cleanup_errors($(this));
        $(this).find("input[type='submit']").button("loading");

        var data = {};
        data.enabled = $("#schedule_enabled").val();
        data.name = $.trim($("#schedule_name").val());
        data.type = scope.find(".nav li.active a").attr("href").replace("#", "");
        data.trigger_ids = $("#schedule_trigger_ids").val();
        data.days = []
        $("#schedule_days .day input:checked").each(function() {
            data.days.push($(this).val());
        });

        var tab = scope.find("#" + data.type);
        tab.find("input, select").each(function() {
            var input = $(this);
            var name = input.attr("name").match(/(\[(.+)\])/)[1]
            data[name] = input.val();
        });

        $.ajax($(this).attr("action"), {
            type: $(this).find("input[name='_method']").val() || "POST",
            data: data,
            success: function() {
                window.location = "/schedules";
            },
            error: function(xhr) {
                scope.find("input[type='submit']").button("reset");
                Remotehue.Helpers.Errors.handle_errors(scope, xhr);
            }
        });
    });

    // Tabs
    scope.find(".nav li a").click(function(event) {
        event.preventDefault();
        $(this).tab("show");

        if( $(this).attr("href") == "#sunrise" || $(this).attr("href") == "#sunset" ) {
            if( $("#set-location").length == 1 ) {
                $("#set-location .modal").modal();
                setup_location_form()
            }
        }
    });

    var active = scope.find(".nav li.active a").tab("show");
    scope.find(active.attr("href")).addClass("active");
}