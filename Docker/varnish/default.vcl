
vcl 4.0;

import std;

include "backends.vcl";
include "acls.vcl";
include "error.vcl";


sub vcl_recv {
    # Only allow Jenkins Purge access
    if (req.method == "PURGE") {
        if (std.ip(regsub(req.http.X-Forwarded-For, "[, ].*$", ""), client.ip) !~ admin) {
        return (synth(405, "Not allowed."));
    }

    ban("req.http.host ~ " + req.http.host + " && req.url ~ " + req.url); 
        return (synth(200, "Purge"));
    }

    # Block all POST requests
    if (req.method == "POST") {
        return (synth(403, "Fuck off"));
    }

    # Detect and set CloudFlare client IP
    if (req.restarts == 0) {
        if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
            if (req.http.CF-Connecting-IP) {
                unset req.http.X-Forwarded-For;
                set req.http.X-Forwarded-For = req.http.CF-Connecting-IP;
            }
        }
    }

    # workaround cloudflare/varnish
    if (req.http.host ~ "(?i)^(www.)?rubyninja\.(com|org|net)") {
        if (req.http.host !~ "www.antoniobaltazar.com") {
            set req.http.host = "www.antoniobaltazar.com";
            return (synth(750, "http://" + req.http.host + "/blog" + req.url));
        }
    }

    set req.backend_hint = default;

    # Drop all cookies
    unset req.http.cookie;
}
  
sub vcl_backend_response {
    # Drop any cookies sent by App
    unset beresp.http.set-cookie;
    
    set beresp.http.X-Cacheable = "YES";
    set beresp.ttl = 600m; # cache content for 300 minutes (10 hours).

    # Exlicitly disable cache
    if (bereq.url ~ "/do_not_cache\.html") {
        set beresp.ttl = 0s;
    }

    return(deliver);
}

# https://info.varnish-software.com/blog/grace-varnish-4-stale-while-revalidate-semantics-varnish
sub vcl_hit {
    # A pure unadultered hit, deliver it
    if (obj.ttl >= 0s) {
        return (deliver);
    }

    # We have no fresh fish. Lets look at the stale ones.
    if (std.healthy(req.backend_hint)) {
        # Backend is healthy. Limit age to 30s.
        if (obj.ttl + 30s > 0s) {
            set req.http.grace = "normal(limited)";
            return (deliver);

        # No candidate for grace. Fetch a fresh object.
        } else {
            return(miss);
        }
    } else {
        # backend is sick - use full grace
        if (obj.ttl + obj.grace > 0s) {
            set req.http.grace = "full";
            return (deliver);

        # no graced object.
        } else {
            return(miss);
        }
    }
}

sub vcl_miss {
    return (fetch);
}

sub vcl_deliver {
    # Add a header for identifying cache hits/misses.
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    # Remove server name, and also remove extra headers added by Varnish
    unset resp.http.Server;
    unset resp.http.X-Powered-By;
    unset resp.http.Via;
    unset resp.http.X-Varnish;
    unset resp.http.X-Mod-Pagespeed;
    unset resp.http.Link;

    # Security headers
    set resp.http.X-XSS-Protection = "1; mode=block";
    set resp.http.X-Content-Type-Options = "nosniff";
    set resp.http.X-Frame-Options = "SAMEORIGIN";

    # Custom headers
    set resp.http.X-Powered-By = "Unicorns";
    set resp.http.X-hacker = "Alpha01";
}
