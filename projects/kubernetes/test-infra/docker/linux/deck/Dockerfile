ARG BASE_IMAGE
FROM $BASE_IMAGE

# Copy local files instead of downloading using external CDN
COPY docker/linux/deck/static/material/1.3.0/material.min.js /static/material/1.3.0/
COPY docker/linux/deck/static/material/1.3.0/material.indigo-pink.min.css /static/material/1.3.0/


# Update HTML references
RUN find /var/run/ko/template -type f -iname '*.html' -exec sed -i -e 's,https://code.getmdl.io/1.3.0/,/static/material/1.3.0/,g' {} \;
RUN find /var/run/ko/lenses/podinfo -type f -iname '*.html' -exec sed -i -e 's,https://code.getmdl.io/1.3.0/,/static/material/1.3.0/,g' {} \;
