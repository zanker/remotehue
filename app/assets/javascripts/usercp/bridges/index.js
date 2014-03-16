Remotehue.PAGES["usercp/bridges/index"] = function() {
    $("#usercp_bridges_index .resync").click(function(event) {
        event.preventDefault();

        $(this).button("loading");
        $.ajax($(this).attr("href"), {
            type: "PUT",
            success: function() {
                window.location.reload();
            }
        });
    });
}