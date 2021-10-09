# build Sphinx documentation
FROM sphinxdoc/sphinx:4.1.2 as build

RUN apt-get update && apt-get install -y libpq-dev gcc
WORKDIR /docs

ADD docs /docs/source
ADD requirements.txt /docs

RUN pip3 install --upgrade pip \
    && pip3 install -r requirements.txt \
    && sphinx-build -M html source build

# serve the documentation with nginx
FROM nginx:alpine

COPY --from=build /docs/build/html /usr/share/nginx/html
