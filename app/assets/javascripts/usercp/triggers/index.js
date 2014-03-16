Remotehue.PAGES["usercp/triggers/index"] = function() {
    var regenerate_url, active_url;
    var setup_loading = $("#trigger-setup .modal-body").html();
    $("#usercp_triggers_index .setup").click(function(event) {
        event.preventDefault();

        regenerate_url = $(this).data("regenerate");
        active_url = $(this).attr("href");

        $("#trigger-setup .modal-body").html(setup_loading);
        $("#trigger-setup").modal({remote: active_url});
    });

    $("#trigger-setup .pull-right").click(function(event) {
        event.preventDefault();
        if( !confirm(I18n.t("usercp.triggers.index.js.regenerate_confirm")) ) return;

        $(this).button("loading");
        $.ajax(regenerate_url, {
            type: "POST",
            success: function() {
                $.ajax(active_url, {
                    type: "GET",
                    success: function(res) {
                        $("#trigger-setup .pull-right").button("reset");
                        $("#trigger-setup .modal-body").html(res);
                    }
                });
            }
        });
    });

    var history_loading = $("#trigger-history .modal-body").html();
    $("#usercp_triggers_index .history").click(function(event) {
        event.preventDefault();
        $("#trigger-history .modal-body").html(history_loading);
        $("#trigger-history").modal({remote: $(this).attr("href")});
    });

    $("#usercp_triggers_index .delete").click(function(event) {
        event.preventDefault();

        var scope = $(this);
        scope.attr("disabled", true);

        Remotehue.Helpers.Modal.confirm({
            title: "usercp.triggers.index.js.are_you_sure",
            body: "usercp.triggers.index.js.confirm_delete",
            on_cancel: function(modal) { scope.button("reset"); },
            on_confirm: function(modal) {
                modal.find(".btn.confirm").val(I18n.t("usercp.triggers.index.js.deleting")).addClass("disabled");

                $.ajax(scope.attr("href"), {
                    type: "DELETE",
                    complete: function() {
                        window.location.reload();
                    },
                });
            }
        });
    });
}