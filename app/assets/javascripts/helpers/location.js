Remotehue.Helpers.Location = {
    setup: function(args) {
        args.loading.hide();

        // Handle map rendering and management
        var center = new google.maps.LatLng(args.latitude || 40.714623, args.longitude || -74.006605);
        var map = new google.maps.Map(document.getElementById("map"), {
            zoom: (args.latitude && args.longitude) ? 14 : 10,
            center: center,
            mapTypeControl: true,
            mapTypeControlOptions: {style: google.maps.MapTypeControlStyle.DROPDOWN_MENU},
            zoomControl: true,
            zoomControlOptions: {style: google.maps.ZoomControlStyle.SMALL},
            scaleControl: false,
            streetViewControl: false,
            mapTypeId: google.maps.MapTypeId.ROADMAP
        });

        this.map = map;

        var geocoder = new google.maps.Geocoder();
        var geo_address = $("#address input[type='text']");
        var geo_button = $("#address input[type='button']");

        $("#address input[type='button']").click(function(event) {
            $(this).button("loading");

            geocoder.geocode({address: $.trim(geo_address.val())}, function(results, status) {
                map.setZoom(14);
                map.setCenter(results[0].geometry.location);
                geo_button.button("reset");

                update_solar_time();
            });
        });

        geo_address.keypress(function(event) {
            if( event.which == 13 ) {
                event.preventDefault();
                geo_button.trigger("click");
            }
        });

        // Try using HTML5 geocoding if available
        if( navigator.geolocation && !args.latitude && !args.longitude ) {
            navigator.geolocation.getCurrentPosition(function(position) {
                position = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
                map.setCenter(position);

                geocoder.geocode({"latLng": position}, function(results, status) {
                    if( status != google.maps.GeocoderStatus.OK ) return;

                    map.setZoom(12);
                    map.setCenter(results[0].geometry.location);

                    geo_address.val(results[0].formatted_address);
                });
            });
        }

        var loading, last_center;

        function update_solar_time() {
            if( loading ) return;

            var center = map.getCenter();
            if( last_center == center ) return;

            last_center = map.getCenter();
            args.loading.show();

            $.ajax(args.url, {
                type: "POST",
                data: {latitude: center.lat(), longitude: center.lng()},
                complete: function(res, status) {
                    if( status == "success" ) {
                        res = JSON.parse(res.responseText);

                        args.label.html(args.text.replace("[[sunrise]]", "<strong>" + res.sunrise + "</strong>").replace("[[sunset]]", "<strong>" + res.sunset + "</strong>").replace(/\[\[zone\]\]/g, "<strong>" + res.timezone + "</strong>"));
                    }

                    args.loading.hide();

                    loading = null;
                }
            });
        }

        var map_timer;
        google.maps.event.addListener(map, "center_changed", function() {
            if( map_timer ) clearTimeout(map_timer);
            map_timer = setTimeout(update_solar_time, 1000);
        });
    }
}