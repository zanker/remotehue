Remotehue.PAGES["usercp/bridges/edit"] = Remotehue.PAGES["usercp/bridges/new"] = function() {
    mixpanel.track_links("#meethue-login .pull-left", "Bridge -> Manage -> Cancel MeetHue Login");
    mixpanel.track_links("#setup-portal .pull-left", "Bridge -> Manage -> Cancel Setup Portal");

    var flag_leave;
    var bridge_id;
    $(window).bind("beforeunload", function() {
        if( !flag_leave ) return;
        return I18n.t("usercp.bridges.manage.js.are_you_sure")
    });

    // Saving bridge so we can store data without going through JS
    function save_bridge() {
        if( !$("#bridge_api_key").is(":visible") ) {
            return show_step2();
        }

        var scope = $("#step1").find("form");
        scope.find("input[type='submit']").button("saving")
        // Bootstrap is dumb
        setTimeout(function() {
            scope.find("input[type='submit']").attr("disabled", true);
        }, 0);

        $.ajax(scope.attr("action"), {
            type: $("#bridge_api_key").is(":visible") ? "PUT": "POST",
            data: {ip: $("#bridge_local_ip").val(), api_key: $("#bridge_api_key").val()},
            success: function(data) {
                show_step2();
            },
            error: function(xhr) {
                scope.find("input[type='submit']").button("reset");
                Remotehue.Helpers.Errors.handle_errors(scope, xhr);
            }
        });
    }

    // Handling a bridge that's not linked to portalservices yet
    var portal_scope = $("#setup-portal");

    function recheck_portalservice() {
        $.ajax("http://" + $.trim($("#bridge_local_ip").val()) + "/api/" + $("#bridge_api_key").val(), {
            success: function(bridge) {
                if( !bridge.config.portalservices ) {
                    portal_scope.find(".pull-right").button("reset");
                    portal_scope.find(".setting-up").hide();
                    portal_scope.find(".not-setup").show();
                    setTimeout(recheck_portalservice, 2000);
                } else {
                    portal_scope.modal("hide");
                    save_bridge();
                }
            }
        });
    }

    portal_scope.find(".pull-right").click(function() {
        mixpanel.track("Bridge -> Manage -> Portal Service Checked");

        portal_scope.find(".pull-right").button("loading");
        recheck_portalservice();
    });

    function portalservice_setup(bridge) {
        // Set the bridge ID since we need it to figure out what bridge to request
        // on our first setup
        bridge_id = bridge.config.mac.replace(/:/g, "").replace(/([a-z0-9]{6})/, '$1fffe');

        if( !bridge.config.portalservices ) {
            portal_scope.find(".pull-right").button("reset");
            mixpanel.track("Bridge -> Manage -> Portal Service Required");

            portal_scope.modal({keyboard: false});
            $(".modal-backdrop").unbind("click");
        } else {
            mixpanel.track("Bridge -> Manage -> Portal Service Setup");
            save_bridge();
        }
    }

    // Login time
    function show_step2() {
        mixpanel.track("Bridge -> Manage -> Step 2");

        $("#bridge_local_ip").attr("disabled", true);
        $("#step1 input[type='submit']").hide();
        $("#step2").slideDown("fast");

        if( $("#meethue-login").length > 0 ) {
            $("#meethue-login").modal({keyboard: false});
            $(".modal-backdrop").unbind("click");
        } else if( $("#step2 .status").length > 0 ) {
            var scope = $("#step2").find("form");
            scope.find("input[type='submit']").button("loading")
            $.ajax(scope.data("meethue-check"), {
                type: "PUT",
                success: function(data) {
                    flag_leave = null;
                    window.location = "/bridges";
                },
                error: function(xhr) {
                    scope.find("input[type='submit']").button("reset");
                    scope.find(".status").slideUp("fast");
                    scope.find(".login").slideDown("fast");

                    if( xhr.status == 500 ) {
                        Remotehue.Helpers.Errors.request_error(xhr.status);
                    }
                }
            });
        }
    }

    $("#step1 form").submit(function(event) {
        event.preventDefault();

        Remotehue.Helpers.Errors.cleanup_errors($(this));

        var ip = $.trim($("#bridge_local_ip").val());
        if( ip == "" ) {
            Remotehue.Helpers.Errors.display_error("bridge", "local_ip", "", [I18n.t("usercp.bridges.manage.js.enter_ip")]);
            return;
        }

        flag_leave = true;

        $(this).find("input[type='submit']").button("loading");
        var scope = $(this);
        $.ajax("http://" + ip + "/api/" + $("#bridge_api_key").val(), {
            timeout: 5 * 1000,
            success: function(data, status, xhr) {
                if( data[0] && data[0].error && data[0].error.type == 1 ) {
                    mixpanel.track("Bridge -> Manage -> Auth Required");

                    Remotehue.Helpers.Modal.show({color: "error", title: "usercp.bridges.manage.js.bridge_unauthorized", body: "usercp.bridges.manage.js.bridge_press_link"});

                    function check_authorization() {
                        $.ajax("http://" + ip + "/api", {
                            type: "POST",
                            dataType: "json",
                            data: JSON.stringify({devicetype: "Remote Hue", username: $("#bridge_api_key").val()}),
                            success: function(data) {
                                if( data[0] && data[0].success && data[0].success["username"] ) {
                                    $("#bridge-status").removeClass("text-error").addClass("text-success").text(I18n.t("usercp.bridges.manage.js.authorized"));
                                    Remotehue.Helpers.Modal.hide();

                                    // Load configuration
                                    $.ajax("http://" + ip + "/api/" + $("#bridge_api_key").val(), {
                                        success: function(data) {
                                            portalservice_setup(data);
                                        }
                                    });

                                } else {
                                    setTimeout(check_authorization, 1500);
                                }
                            }
                        });
                    }

                    setTimeout(check_authorization, 1500);
                } else {
                    mixpanel.track("Bridge -> Manage -> Authed");
                    $("#bridge-status").removeClass("text-error").addClass("text-success").text(I18n.t("usercp.bridges.manage.js.authorized"));
                    portalservice_setup(data);
                }
            },
            error: function(xhr, status, error) {
                scope.find("input[type='submit']").button("reset");
                if( error == "timeout" || error == "error" ) {
                    mixpanel.track("Bridge -> Manage -> Not Found");
                    Remotehue.Helpers.Modal.show({no_keyboard: true, color: "error", title: "usercp.bridges.manage.js.bridge_not_found", body: "usercp.bridges.manage.js.bridge_not_on_network"});
                } else if( xhr.status == 500 ) {
                    Remotehue.Helpers.Errors.request_error(xhr.status);
                }
            }
        });
    });

    var load_timeout;
    $("#step2 form").submit(function(event) {
        event.preventDefault();

        Remotehue.Helpers.Errors.cleanup_errors($(this));

        var email = $.trim($("#email").val());
        if( email == "" ) {
            Remotehue.Helpers.Errors.display_error(null, "email", "", [I18n.t("usercp.bridges.manage.js.enter_email")]);
            return;
        }

        var password = $.trim($("#password").val());
        if( password == "" ) {
            Remotehue.Helpers.Errors.display_error("bridge", "local_ip", "", [I18n.t("usercp.bridges.manage.js.enter_password")]);
            return;
        }

        $(this).find("input[type='submit']").button("loading");
        load_timeout = setTimeout(function() { scope.find("input[type='submit']").val(I18n.t("usercp.bridges.manage.js.still_authenticating"))}, 5000);

        var scope = $(this);
        $.ajax($(this).attr("action"), {
            type: $(this).attr("method"),
            data: {email: email, password: password, ip: $("#bridge_local_ip").val(), api_key: $("#bridge_api_key").val(), bridge_id: bridge_id},
            success: function(data) {
                flag_leave = null;
                window.location = "/bridges";
            },
            error: function(xhr) {
                clearTimeout(load_timeout);
                scope.find("input[type='submit']").button("reset");
                if( xhr.status == 500 ) {
                    return Remotehue.Helpers.Errors.request_error(xhr.status);
                }

                var res = JSON.parse(xhr.responseText);
                if( res.scope ) {
                    Remotehue.Helpers.Errors.handle_errors(scope, xhr);
                } else {
                    Remotehue.Helpers.Modal.show({color: "error", title: "usercp.bridges.manage.js.meethue_error", body: "usercp.bridges.manage.js.meethue." + res.error})
                }
            }
        });
    });
}