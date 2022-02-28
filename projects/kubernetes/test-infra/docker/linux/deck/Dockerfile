ARG BASE_IMAGE #gcr.io/k8s-prow/deck:v20200924-369a496323 

FROM $BASE_IMAGE

RUN find /template -type f -iname '*.html' -exec sed -i -e 's,https://code.getmdl.io/1.3.0/,/static/,g' {} \;
RUN find /lenses/podinfo -type f -iname '*.html' -exec sed -i -e 's,https://code.getmdl.io/1.3.0/,/static/,g' {} \;

RUN wget https://code.getmdl.io/1.3.0/material.min.js -P /static
RUN wget https://code.getmdl.io/1.3.0/material.indigo-pink.min.css -P /static
