sub vcl_backend_error {

	if (beresp.status == 750) {
        	set beresp.http.Location = beresp.reason;
        	set beresp.status = 301;
        	return(deliver);
    	}

	if (beresp.status == 503) {
        set beresp.http.Content-Type = "text/html; charset=utf-8";
        synthetic({"<!DOCTYPE html>
    <html>
    <head>
    <style>
    body {
        background-color: #9B785C;
        font-family:"Helvetica Neue",Arial,Helvetica,sans-serif;
        color:#000
    }
    </style>
    <title>Oops</title>
    </head>
    <body>
        <h1>Server is experiencing some stability issues</h1>
        <p>Refresh page or come back later.</p>
    </body>
    </html>"});
    }
    return (deliver);
}

sub vcl_synth {

	if (resp.status == 750) {
        	set resp.http.Location = resp.reason;
        	set resp.status = 301;
        	return(deliver);
    	}

	if (resp.status == 503) {
        set resp.http.Content-Type = "text/html; charset=utf-8";
        synthetic({"<!DOCTYPE html>
    <html>
    <head>
    <style>
    body {
        background-color: #9B785C;
        font-family:"Helvetica Neue",Arial,Helvetica,sans-serif;
        color:#000
    }
    </style>
    <title>Oops</title>
    </head>
    <body>
        <h1>Server is experiencing some stability issues</h1>
        <p>Refresh page or come back later.</p>
    </body>
    </html>"});
    }
    return (deliver);
}
