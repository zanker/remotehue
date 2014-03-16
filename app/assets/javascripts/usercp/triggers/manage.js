Remotehue.PAGES["usercp/triggers/edit"] = Remotehue.PAGES["usercp/triggers/new"] = function() {
    var disclaimer_label = $("#secondary_disclaimer p");
    var disclaimer_text = disclaimer_label.text();

    var secondary_label = $("#trigger_secondary_trigger_id").closest(".controls").find("span")
    var secondary_text = secondary_label.text();
    $("#trigger_name").keyup(function() {
        var val = $(this).val();
        if( val == "" ) val = secondary_label.data("this-one");

        secondary_label.html(secondary_text.replace("{{name}}", "<strong>" + val + "</strong>"));
        disclaimer_label.html(disclaimer_text.replace("{{name}}", "<strong>" + val + "</strong>"));
    }).trigger("keyup");

    var delay_label = $("#trigger_secondary_delay").closest(".controls").find("span");
    var delay_text = delay_label.text();
    $("#trigger_secondary_trigger_id").change(function() {
        var val = $(this).val();
        if( val == "" ) {
            $("#trigger_secondary_delay").attr("disabled", true);
            delay_label.hide();
        } else {
            $("#trigger_secondary_delay").attr("disabled", false);
            delay_label.show().html(delay_text.replace("{{name}}", "<strong>" + $(this).find("option:selected").text() + "</strong>"));
        }

    }).trigger("change");

    var scope = $("#usercp_triggers_edit, #usercp_triggers_new").find("form");
    scope.submit(function(event) {
        event.preventDefault();

        Remotehue.Helpers.Errors.cleanup_errors($(this));
        $(this).find("input[type='submit']").button("loading");

        var data = {};
        data.name = $.trim($("#trigger_name").val());
        data.type = scope.find(".nav li.active a").attr("href").replace("#", "");
        data.secondary_trigger_id = $("#trigger_secondary_trigger_id").val();
        data.secondary_delay = $("#trigger_secondary_delay").val();
        data.transitiontime = $("#trigger_transitiontime").val();

        var tab = scope.find("#" + data.type);
        tab.find("input, select").each(function() {
            var input = $(this);
            var name = input.attr("name").match(/(\[.+\])/)[1]
            data[name] = input.val();
        });

        var cp;
        if( data.type == "flash" || data.type == "on" ) {
            cp = tab.find(".colorpicker").first();
            data.color = cp.data("last");
            if( data.color.colormode == "ct" ) {
                delete(data.color.hue);
                delete(data.color.sat);
            } else {
                delete(data.color.ct);
            }

            if( scope.find("#trigger_color_transitiontime").length > 0 ) {
                data.transitiontime = parseInt(scope.find("#trigger_color_transitiontime").val());
            }
        }

        $.ajax($(this).attr("action"), {
            type: $(this).find("input[name='_method']").val() || "POST",
            data: data,
            success: function() {
                window.location = "/triggers";
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
    });

    var active = scope.find(".nav li.active a").tab("show");
    scope.find(active.attr("href")).addClass("active");

    // Colorpickers
    // Color/brightness
    function update_color(last, bounding, x, y) {
        var percent_y = y / bounding.height;
        var percent_x = x / bounding.width;

        // 0 - 0.245 is color temperature, 0.246 - 1 is hue/sat
        if( percent_y < 0.245 ) {
            var ct = Math.round((Remotehue.Hue.ct.max - Remotehue.Hue.ct.min) * percent_x) + Remotehue.Hue.ct.min;
            last.colormode = "ct";
            last.ct = ct;

        } else {
            var hue = Math.round(Remotehue.Hue.hue.max * percent_x);
            var sat = Math.round(Remotehue.Hue.sat.max * (percent_y - 0.245) / 0.755);

            last.colormode = "hs";
            last.hue = hue;
            last.sat = sat;
        }
    }

    function update_bri(last, bounding, x, y) {
        var percent = y / bounding.height;

        var bri = Math.round(Remotehue.Hue.bri.max * percent);
        if( bri == last.bri ) return;
        last.bri = bri;
    }

    // Cursor movement
    var position = {};
    function update_cursor(pointer, callback, last, bounding, x, y) {
        // Make sure it doesn't go outside of the box
        if( x > bounding.width ) x = bounding.width;
        if( x < 0 ) x = 0;

        if( y > bounding.height ) y = bounding.height;
        if( y < 0 ) y = 0;

        if( callback ) callback(last, bounding, x, y);

        // Center it under the cursor
        y -= 7;
        x -= 7;

        position.top = y;
        position.left = bounding.force_left ? bounding.force_left : x;
        pointer.css(position);
    }

    function move_cursor(event, callback, last, bounding, pointer) {
        event.preventDefault();

        // For touch based events
        if( event.originalEvent.changedTouches ) {
            event = event.originalEvent.changedTouches[0]
        }

        update_cursor(pointer, callback, last, bounding, event.pageX - bounding.left, event.pageY - bounding.top);
    }

    // Setup
    var draggable = {}
    var drag_id = 0;
    $(".colorpicker").each(function(id, cp) {
        cp = $(cp);
        var pointer = cp.find(".pointer");

        var last = {};
        cp.data("last", last);

        var bri_pointer, color_pointer
        cp.find(".draggable").each(function() {
            var parent = $(this);
            parent.attr("id", "drag-" + (drag_id += 1));

            var bounding = parent.position();
            bounding.top += parseInt(parent.css("margin-top"));

            bounding.bottom = bounding.top + parent.height();
            bounding.right = bounding.left + parent.width();

            bounding.width = bounding.right - bounding.left;
            bounding.height = bounding.bottom - bounding.top;

            if( parent.hasClass("bri") ) {
                bounding.force_left = -8;
            }

            var pointer = parent.find(".pointer");
            pointer.data("bounding", bounding);

            draggable[parent.attr("id")] = [pointer, bounding, last, parent.hasClass("bri") ? update_bri : update_color];

            if( parent.hasClass("bri") ) {
                pointer.css({top: 0, left: -8});
                bri_pointer = pointer;
            } else {
                color_pointer = pointer;
            }
        });

        var color = cp.data("color");
        if( !color ) {
            color = {bri: Remotehue.Hue.bri.max, ct: Remotehue.Hue.ct.min};
        }

        for( var key in last ) delete(last[key]);
        for( var key in color ) last[key] = color[key];

        var bounding = bri_pointer.data("bounding");
        update_cursor(bri_pointer, null, null, bounding, 0, (last.bri / Remotehue.Hue.bri.max) * bounding.height);

        bounding = color_pointer.data("bounding");
        var y = 0, x = 0;
        if( last.ct ) {
            last.colormode = "ct";

            y = 0.1225;
            x = bounding.width * ((last.ct - Remotehue.Hue.ct.min) / (Remotehue.Hue.ct.max - Remotehue.Hue.ct.min));
        } else {
            last.colormode = "hs";

            y = bounding.height * 0.245
            y += (bounding.height - y) * (last.sat / Remotehue.Hue.sat.max);
            x = bounding.width * (last.hue /Remotehue.Hue.hue.max);
        }

        update_cursor(color_pointer, null, null, bounding, x, y);
    });

    var moving;
    $(document).on("mousedown touchstart", function(event) {
        var target = $(event.target).closest(".draggable").attr("id");
        if( !draggable[target] ) return;

        // Update bounding box
        var bounding = draggable[target][1];
        var parent = draggable[target][0].closest(".draggable");
        var pos = parent.position();
        for( var key in pos ) bounding[key] = pos[key];

        bounding.top += parseInt(parent.css("margin-top"));

        bounding.bottom = bounding.top + parent.height();
        bounding.right = bounding.left + parent.width();

        bounding.width = bounding.right - bounding.left;
        bounding.height = bounding.bottom - bounding.top;

        // Get ready to move
        var last = draggable[target][2];
        last.dragging = null;
        move_cursor(event, draggable[target][3], last, draggable[target][1], draggable[target][0]);
        last.dragging = true;
        moving = draggable[target];
    });

    $(document).on("mouseup touchend", function(event) {
        if( moving && moving[2] ) {
            moving[2].dragging = null;
            moving = null;
        }
    });

    $(document).on("mousemove touchmove", function(event) {
        if( moving && moving[0] ) {
            move_cursor(event, moving[3], moving[2], moving[1], moving[0]);
        }
    });
}