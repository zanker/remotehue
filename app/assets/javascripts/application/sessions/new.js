Remotehue.PAGES["sessions/new"] = function() {
    var zone = jstz.determine();
    if( zone && zone.name() ) {
        var exp = new Date(Date.now() + (60 * 60 * 1000));
        document.cookie = "timezone=" + zone.name() + "; expires=" + exp.toUTCString();
    }
}