ARG BASE_IMAGE
FROM $BASE_IMAGE

# Patch Alpine OS packages for known CVEs before publishing to AWS ECR.
# Upstream Prow images lag the pinned Alpine stable repo, so this pulls
# patch-level security fixes.
RUN apk --no-cache upgrade

# Copy local files instead of downloading using external CDN
COPY docker/linux/deck/static/material/1.3.0/material.min.js /var/run/ko/static/material/1.3.0/
COPY docker/linux/deck/static/material/1.3.0/material.indigo-pink.min.css /var/run/ko/static/material/1.3.0/

# Update HTML references
RUN find /var/run/ko/template -type f -iname '*.html' -exec sed -i -e 's,https://code.getmdl.io/1.3.0/,/static/material/1.3.0/,g' {} \;
RUN find /var/run/ko/lenses -type f -iname '*.html' -exec sed -i -e 's,https://code.getmdl.io/1.3.0/,/static/material/1.3.0/,g' {} \;
