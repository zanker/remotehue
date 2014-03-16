Remotehue.PAGES["usercp/settings/edit"] = function() {
    var scope = $("#usercp_settings_edit form");
    Remotehue.Helpers.Location.setup({url: scope.data("solar-url"), text: $("#solar-time").data("text"), label:  $("#solar-time span"), loading: $("#solar-time img"), latitude: $("#map").data("latitude"), longitude: $("#map").data("longitude")})

    scope.submit(function(event) {
        event.preventDefault();

        Remotehue.Helpers.Errors.cleanup_errors($(this));
        $(this).find("input[type='submit']").button("loading");

        var data = {};
        var center = Remotehue.Helpers.Location.map.getCenter();
        data.latitude = center.lat();
        data.longitude = center.lng();

        $(this).find(".control-group").find("input, select").each(function() {
            var input = $(this);
            if( !input.attr("name") ) return;
            var name = input.attr("name").match(/(\[.+\])/)[1]
            data[name] = input.val();
        });

        $.ajax($(this).attr("action"), {
            type: $(this).find("input[name='_method']").val() || "POST",
            data: data,
            success: function() {
                window.location = "/bridges";
            },
            error: function(xhr) {
                scope.find("input[type='submit']").button("reset");
                Remotehue.Helpers.Errors.handle_errors(scope, xhr);
            }
        });
    });
}