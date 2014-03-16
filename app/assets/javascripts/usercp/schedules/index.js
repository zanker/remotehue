Remotehue.PAGES["usercp/schedules/index"] = function() {
    var history_loading = $("#schedule-history .modal-body").html();
    $("#usercp_schedules_index .history").click(function(event) {
        event.preventDefault();
        $("#schedule-history .modal-body").html(history_loading);
        $("#schedule-history").modal({remote: $(this).attr("href")});
    });

    $("#usercp_schedules_index .delete").click(function(event) {
        event.preventDefault();

        var scope = $(this);
        scope.attr("disabled", true);

        Remotehue.Helpers.Modal.confirm({
            title: "usercp.schedules.index.js.are_you_sure",
            body: "usercp.schedules.index.js.confirm_delete",
            on_cancel: function(modal) { scope.button("reset"); },
            on_confirm: function(modal) {
                modal.find(".btn.confirm").val(I18n.t("usercp.schedules.index.js.deleting")).addClass("disabled");

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