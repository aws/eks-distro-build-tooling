ARG BASE_IMAGE
FROM $BASE_IMAGE

# Copy local files instead of downloading using external CDN
COPY static/material/1.3.0/material.min.js /static/material/1.3.0/
COPY static/material/1.3.0/material.indigo-pink.min.css /static/material/1.3.0/


# Update HTML references
RUN find /template -type f -iname '*.html' -exec sed -i -e 's,https://code.getmdl.io/1.3.0/,/static/material/1.3.0/,g' {} \;
RUN find /lenses/podinfo -type f -iname '*.html' -exec sed -i -e 's,https://code.getmdl.io/1.3.0/,/static/material/1.3.0/,g' {} \;
