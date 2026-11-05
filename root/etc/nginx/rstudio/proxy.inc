# Included by every location: a location that sets any proxy_set_header or
# add_header of its own stops inheriting them from the server block.

# No URI part, so rserver receives the raw request URI unchanged.
proxy_pass http://127.0.0.1:8788;

proxy_set_header Host       $http_host;
proxy_set_header Upgrade    $http_upgrade;
proxy_set_header Connection $connection_upgrade;
proxy_set_header Cookie     $cookie_forwarded;

# resty puts the user's appstore access token here; rserver does not use it,
# and /p/ would pass it to local apps. (resty's REMOTE_USER header is already
# dropped: nginx discards header names containing underscores.)
proxy_set_header Authorization "";

proxy_hide_header X-Frame-Options;
proxy_hide_header X-Content-Type-Options;
add_header X-Frame-Options        SAMEORIGIN always;
add_header X-Content-Type-Options nosniff    always;
