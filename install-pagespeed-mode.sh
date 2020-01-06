#!/bin/sh
wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_x86_64.rpm
yum install at
rpm2cpio ./mod-pagespeed-stable_current_x86_64.rpm | cpio -idmv
cp ./usr/lib64/httpd/modules/mod_pagespeed_ap24.so /usr/local/apache2/modules/mod_pagespeed_ap24.so
cp ./usr/bin/pagespeed_js_minify /usr/local/apache2/bin/pagespeed_js_minify
