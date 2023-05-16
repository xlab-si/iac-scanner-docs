# IaC Scanner documentation
This repository holds the documentation for the [IaC Scanner].

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/xlab-si/iac-scanner-docs/ci_cd.yml?branch=main)](https://github.com/xlab-si/iac-scanner-docs/actions)
[![GitHub deployments](https://img.shields.io/github/deployments/xlab-si/iac-scanner-docs/github-pages?label=gh-pages)](https://github.com/xlab-si/iac-scanner-docs/deployments)
[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/xscanner/docs?color=blue&label=docker)](https://hub.docker.com/r/xscanner/docs)

## Table of Contents
  - [Description](#purpose-and-description)
  - [Run with Docker](#run-with-docker)
  - [Local building and testing](#local-building-and-testing)
  - [License](#license)
  - [Contact](#contact)
  - [Acknowledgement](#acknowledgement)

## Purpose and description
This project documents all the related IaC Scanner tools and services.
The documentation is available on [GitHub Pages].

## Run with Docker
You can run the docs using a public [xscanner/docs] Docker image as follows:

```console
# run IaC Scanner documentation in a Docker container and navigate to localhost:8000
$ docker run --name iac-scanner-docs -p 8000:80 xscanner/docs
```

Or you can build the image locally and run it as follows:

```console
# build Docker container
$ docker build -t iac-scanner-docs .
# run IaC Scanner documentation in a Docker container and navigate to localhost:8000
$ docker run --name iac-scanner-docs -p 8000:80 iac-scanner-docs
```

## Local building and testing
For documenting the IaC Scanner we use the [Sphinx documentation tool].
Here we can render Sphinx Documentation from RST files and we use [Read the Docs] theme.

To test the documentation locally run the commands below:

```console
# create and activate a new Python virualenv
$ python3 -m venv .venv && . .venv/bin/activate
# update pip and install Sphinx requirements
(.venv) $ pip install --upgrade pip
(.venv) $ pip install -r requirements.txt
# build the HTML documentation
(.venv) $ sphinx-build -M html docs build
# build the Latex and PDF documentation
(.venv) $ sphinx-build -M latexpdf docs build
```

After that you will found rendered documentation HTML files in `build` folder and you can open and view them inside 
your browser. 

## License
This work is licensed under the [Apache License 2.0].

## Contact
You can contact the xOpera team by sending an email to [xopera@xlab.si].

## Acknowledgement
This project has received funding from the European Union’s Horizon 2020 research and innovation programme under Grant 
Agreement No. 101000162 ([PIACERE]).

[IaC Scanner]: https://xlab-si.github.io/iac-scanner-docs/
[GitHub Pages]: https://xlab-si.github.io/iac-scanner-docs/
[xscanner/docs]: https://hub.docker.com/r/xscanner/docs
[Sphinx documentation tool]: https://www.sphinx-doc.org/en/master/
[Read the Docs]: https://readthedocs.org/
[Apache License 2.0]: https://www.apache.org/licenses/LICENSE-2.0
[xopera@xlab.si]: mailto:xopera@xlab.si
[PIACERE]: https://www.piacere-project.eu/
