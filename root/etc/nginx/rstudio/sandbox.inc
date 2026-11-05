# Script still runs, but in an opaque origin. Never add allow-same-origin here:
# script would then share the IDE's origin and could drive the R session.
proxy_hide_header Content-Security-Policy;
add_header Content-Security-Policy "sandbox allow-scripts allow-forms allow-popups allow-modals allow-downloads; frame-ancestors 'self'" always;
