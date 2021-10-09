.. _IaC Scan Runner:

***************
IaC Scan Runner
***************

The **IaC Scan Runner** is a REST API service used to scan IaC (Infrastructure as Code) package by performing various
checks in order to find possible errors and improvements.
The IaC Scan Runner's source code is available in `xlab-si/iac-scan-runner`_ GitHub repository.

.. _IaC Scan Runner REST API:

========
REST API
========

This section focuses on the **IaC Scan Runner REST API** service.

.. _IaC Scan Runner REST API installation:

Installation
############

You can run the REST API using a public `xscanner/runner`_ Docker image as follows:

.. code-block:: bash

    # run IaC Scan Runner REST API in a Docker container and
    # navigate to localhost:8080/swagger or localhost:8080/redoc
    docker run --name iac-scan-runner -p 8080:80 xscanner/runner

.. Tip:: Other methods of running are also explained in `xlab-si/iac-scan-runner`_ GitHub repository.

.. _IaC Scan Runner REST API usage:

Usage
#####

After the setup you will see that the `OpenAPI Specification`_ and interactive `Swagger UI`_ API documentation are
available on ``/swagger``, whereas `ReDoc`_ generated API reference documentation is accessible on ``/redoc``.
You can also retrieve an OpenAPI document that conforms to the `OpenAPI Specification`_ as JSON file on
``/openapi.json`` or as YAML file on ``/openapi.yaml`` (or ``/openapi.yml``).

The IaC Scan Runner API can be used to interact with the main IaC inspection component and initialize IaC scans.
The API includes various IaC checks that can be filtered and configured.
User can choose to execute all or just the selected checks as a part of one IaC scan.
After the scanning process the API will return all the check results.

+-------------------------------------------+-----------------------------------+
| REST API endpoint                         | Description                       |
+===========================================+===================================+
| `/checks`_                                | Retrieve and filter checks        |
+-------------------------------------------+-----------------------------------+
| `/scan`_                                  | Initiate IaC scan                 |
+-------------------------------------------+-----------------------------------+

The API endpoints are further described below.

------------------------------------------------------------------------------------------------------------------------

.. _/checks:

.. http:get:: /checks

    This endpoint lets you retrieve and filter the supported IaC checks.
    You can filter checks by their keynames (use the *keyword* request parameter) and find out whether they are already
    enabled (set the *enabled* parameter) or configured (set the *configured* parameter).
    Checks can also be filtered by their target entity (set the *target_entity_type* parameter) - here we have three
    types of checks - IaC (they only check the code), component (they check IaC requirements and dependencies in order
    to find vulnerabilities) and check that are both IaC and component.
    Each IaC check in the API has its unique name so that it can be distinguished from other checks.
    When no filter is specified, the endpoint lists all IaC checks.

    **Example request**:

    .. tabs::

        .. code-tab:: bash

            $ curl -X 'GET' 'http://127.0.0.1:8000/checks?keyword=Terraform&enabled=true'

        .. code-tab:: python

            import requests
            URL = 'http://127.0.0.1:8000/checks?keyword=Terraform&enabled=true'
            response = requests.get(URL)
            print(response.json())

    **Example response**:

    .. sourcecode:: json

        [
          {
            "name": "tflint",
            "description": "A Pluggable Terraform Linter",
            "enabled": true,
            "configured": true,
            "target_entity_type": "IaC"
          },
          {
            "name": "tfsec",
            "description": "Security scanner for your Terraform code",
            "enabled": true,
            "configured": true,
            "target_entity_type": "IaC"
          },
          {
            "name": "terrascan",
            "description": "Terrascan is a static code analyzer for IaC (defaults to scanning Terraform)",
            "enabled": true,
            "configured": true,
            "target_entity_type": "IaC"
          }
        ]

    :query string keyword: optional keyword from check name or description
    :query boolean enabled: search for checks that are enabled or not
    :query string configured: search for checks that are configured or not
    :query string target_entity_type: search by target entity (one of ``IaC``, ``component``, ``IaC and component``)
    :statuscode 200: Successful Response
    :statuscode 404: Bad Request
    :statuscode 422: Validation Error

------------------------------------------------------------------------------------------------------------------------

.. _/scan:

.. http:post:: /scan

    This is the main endpoint that is used to scan the IaC and gather the results from the executed IaC checks.
    The request body is treated as `multipart`_ (*multipart/form-data* type) and has two parameters.
    The first one is *iac* and is required.
    Here, the user passes his (compressed) IaC package (currently limited to *zip* or *tar*).
    The second parameter is *checks* and is an optional array of checks, which the user wants to executed as a part of
    his IaC scan.
    The IaC checks are selected by their unique names. If the user does not specify that field, all the enabled checks
    are executed.
    The API will warn you if there are any nonexistent, disabled or un-configured checks that you wanted to use.
    After the scanning process the API will return results of all checks (their outputs and return codes).

    **Example request**:

    .. tabs::

        .. code-tab:: bash

            $ curl -X 'POST' 'http://127.0.0.1:8000/scan' -H 'Content-Type: multipart/form-data' -F 'iac=@scaling-example.zip' -F 'checks=bandit,ansible-lint'

        .. code-tab:: python

            import requests
            URL = 'http://127.0.0.1:8000/scan'
            multipart_form_data = {
                'iac': ('scaling-example.zip', open('/path/to/scaling-example.zip', 'rb')),
                'checks': (None, 'bandit,ansible-lint')
            }
            response = requests.patch(URL, files=multipart_form_data)
            print(response.json())

    **Example response**:

    .. sourcecode:: json

        {
          "bandit": {
            "output": "[main]\tINFO\tprofile include tests: None\n[main]\tINFO\tprofile exclude tests: None\n[main]\tINFO\tcli include tests: None\n[main]\tINFO\tcli exclude tests: None\n[main]\tINFO\trunning on Python 3.8.10\nRun started:2021-08-25 11:23:29.960356\n\nTest results:\n\tNo issues identified.\n\nCode scanned:\n\tTotal lines of code: 0\n\tTotal lines skipped (#nosec): 0\n\nRun metrics:\n\tTotal issues (by severity):\n\t\tUndefined: 0\n\t\tLow: 0\n\t\tMedium: 0\n\t\tHigh: 0\n\tTotal issues (by confidence):\n\t\tUndefined: 0\n\t\tLow: 0\n\t\tMedium: 0\n\t\tHigh: 0\nFiles skipped (0):\n",
            "rc": 0
          },
          "ansible-lint": {
            "output": "WARNING  Listing 6 violation(s) that are fatal\n\u001b[34mservice.yaml\u001b[0m:32: \u001b[91myaml\u001b[0m \u001b[2mtoo many spaces inside braces\u001b[0m \u001b[2;91m(braces)\u001b[0m\n\u001b[34mservice.yaml\u001b[0m:32: \u001b[91myaml\u001b[0m \u001b[2mtoo many spaces inside brackets\u001b[0m \u001b[2;91m(brackets)\u001b[0m\n\u001b[34mservice.yaml\u001b[0m:35: \u001b[91myaml\u001b[0m \u001b[2mtoo many spaces inside braces\u001b[0m \u001b[2;91m(braces)\u001b[0m\n\u001b[34mservice.yaml\u001b[0m:35: \u001b[91myaml\u001b[0m \u001b[2mtoo many spaces inside brackets\u001b[0m \u001b[2;91m(brackets)\u001b[0m\n\u001b[34mservice.yaml\u001b[0m:45: \u001b[91myaml\u001b[0m \u001b[2mtoo many spaces inside brackets\u001b[0m \u001b[2;91m(brackets)\u001b[0m\n\u001b[34mservice.yaml\u001b[0m:62: \u001b[91myaml\u001b[0m \u001b[2mtoo many spaces inside brackets\u001b[0m \u001b[2;91m(brackets)\u001b[0m\nYou can skip specific rules or tags by adding them to your configuration file:\n\u001b[2m# .ansible-lint\u001b[0m\n\u001b[94mwarn_list\u001b[0m:  \u001b[2m# or 'skip_list' to silence them completely\u001b[0m\n  - yaml  \u001b[2m# Violations reported by yamllint\u001b[0m\n\nFinished with \u001b[1;36m6\u001b[0m \u001b[1;35mfailure\u001b[0m\u001b[1m(\u001b[0ms\u001b[1m)\u001b[0m, \u001b[1;36m0\u001b[0m \u001b[1;35mwarning\u001b[0m\u001b[1m(\u001b[0ms\u001b[1m)\u001b[0m on \u001b[1;36m9\u001b[0m files.\n",
            "rc": 2
          }
        }

    :form iac: IaC file (currently limited to *zip* or *tar*)
    :form checks: optional array of the selected checks
    :statuscode 200: Successful Response
    :statuscode 400: Bad Request
    :statuscode 422: Validation Error

.. Note:: All API endpoints try to use JSON responses.

.. _IaC Scanner and check reference:

===========================
Scanner and check reference
===========================

The scanner is the main component of the IaC Scan Runner and it initiates the scanning process, which makes the
supplied IaC go through multiple checks.

IaC Scan Runner currently supports the following *IaC checks* that can be executed as part of one *IaC scan*:

+-------------------------------+----------------------------+----------------------------+----------------------------+
| CLI command                   | Target IaC entity          | Enabled (by default)       | Needs configuration        |
+===============================+============================+============================+============================+
| `Ansible Lint`_               | Ansible                    | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `TFLint`_                     | Terraform                  | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `tfsec`_                      | Terraform                  | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `Terrascan`_                  | Terraform                  | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+

The following subsections explain the necessary API actions for each check.

------------------------------------------------------------------------------------------------------------------------

.. _Ansible Lint:

Ansible Lint
############

**Ansible Lint** is a command-line tool for linting playbooks, roles and collections aimed towards any Ansible users
(see `Ansible Lint check`_).

+-------------------------+----------------------------+
| Check ID (from the API) | ``ansible-lint``           |
+-------------------------+----------------------------+
| Enabled (by default)    | yes                        |
+-------------------------+----------------------------+
| Configured (by default) | yes                        |
+-------------------------+----------------------------+
| Documentation           | `Ansible Lint docs`_       |
+-------------------------+----------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional YAML configuration file (see `Ansible Lint config`_).
        You can also skip this configuration and put your local configuration file called ``.ansible-lint`` to the root
        of your IaC package.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _TFLint:

TFLint
######

**TFLint** is a a pluggable Terraform linter.

+-------------------------+---------------------------------+
| Check ID (from the API) | ``tflint``                      |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `TFLint docs`_                  |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional HCL configuration file (see `TFLint config`_).
        You can also skip this configuration and put the TFLint config file named ``.tflint.hcl`` to the root of your
        IaC package.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _tfsec:

tfsec
#####

**tfsec** is a security scanner for your Terraform code (see `tfsec check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``tfsec``                       |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `tfsec docs`_                   |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional JSON or YAML configuration file (see `tfsec config`_).
        You can also skip this configuration and put the tfsec config in the ``.tfsec`` folder in the IaC root and name
        it ``config.json`` or ``config.yml`` and it will be automatically loaded and used.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _Terrascan:

Terrascan
#########

**Terrascan** is a static code analyzer for IaC and defaults to scanning Terraform (see `Terrascan check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``terrascan``                   |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `Terrascan docs`_               |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional TOML configuration file (see `Terrascan config`_).

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _IaC Scan Runner CLI:

===
CLI
===

The **IaC Scan Runner CLI** enables easier setup of IaC Scanner in console environments.

.. _IaC Scan Runner CLI prerequisites:

Prerequisites
#############

The `Scan Runner CLI`_ requires Python 3 and a virtual environment.
In a typical modern Linux environment, we should already be set.
In Ubuntu, however, we might need to run the following commands:

.. code-block:: console

    $ sudo apt update
    $ sudo apt install -y python3-venv python3-wheel python-wheel-common

.. _IaC Scan Runner CLI installation:

Installation
############

IaC Scan Runner CLI is distributed as Python `iac-scan-runner`_ package that is regularly published on `PyPI`_.
The simplest way to test ``iac-scan-runner`` is to install it into virtual environment:

.. code-block:: console

    $ mkdir ~/iac-scan-runner && cd ~/iac-scan-runner
    $ python3 -m venv .venv && . .venv/bin/activate
    (.venv) $ pip install --upgrade pip
    (.venv) $ pip install iac-scan-runner

The development version of the package is available on `TestPyPI`_ and the installation goes as follows.

.. code-block:: console

    (.venv) $ pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ iac-scan-runner

.. _IaC Scan Runner CLI commands:

CLI commands
############

``iac-scan-runner`` it currently allows users to execute the following shell commands:

+-----------------------------+------------------------------------------------+
| CLI command                 | Purpose and description                        |
+=============================+================================================+
| `iac-scan-runner openapi`_  | print `OpenAPI Specification`_                 |
+-----------------------------+------------------------------------------------+
| `iac-scan-runner install`_  | install the IaC Scan Runner prerequisites      |
+-----------------------------+------------------------------------------------+
| `iac-scan-runner run`_      | run the IaC Scan Runner REST API               |
+-----------------------------+------------------------------------------------+

.. tip:: All the CLI commands are equipped with ``-h/--help`` option to help you.

------------------------------------------------------------------------------------------------------------------------

.. _iac-scan-runner openapi:

openapi
*******

.. argparse::
    :module: iac_scan_runner.cli
    :func: create_parser
    :prog: iac-scan-runner
    :path: openapi

------------------------------------------------------------------------------------------------------------------------

.. _iac-scan-runner install:

install
*******

.. argparse::
    :module: iac_scan_runner.cli
    :func: create_parser
    :prog: iac-scan-runner
    :path: install

------------------------------------------------------------------------------------------------------------------------

.. _iac-scan-runner run:

run
***

.. argparse::
    :module: iac_scan_runner.cli
    :func: create_parser
    :prog: iac-scan-runner
    :path: run

------------------------------------------------------------------------------------------------------------------------

.. _xlab-si/iac-scan-runner: https://github.com/xlab-si/iac-scan-runner
.. _xscanner/runner: https://hub.docker.com/r/xscanner/runner
.. _OpenAPI Specification: https://swagger.io/specification/
.. _Swagger UI: https://swagger.io/tools/swagger-ui/
.. _ReDoc: https://redoc.ly/redoc/
.. _multipart: https://swagger.io/docs/specification/describing-request-body/multipart-requests/
.. _Ansible Lint check: https://github.com/willthames/ansible-lint/
.. _Ansible Lint docs: https://ansible-lint.readthedocs.io/en/latest/
.. _Ansible Lint config: https://ansible-lint.readthedocs.io/en/latest/configuring.html
.. _TFLint check: https://github.com/terraform-linters/tflint/
.. _TFLint docs: https://github.com/terraform-linters/tflint/tree/master/docs/user-guide
.. _TFLint config: https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md
.. _tfsec check: https://github.com/aquasecurity/tfsec/
.. _tfsec docs: https://tfsec.dev/docs/installation/
.. _tfsec config: https://tfsec.dev/docs/config/
.. _Terrascan check: https://github.com/accurics/terrascan/
.. _Terrascan docs: https://docs.accurics.com/projects/accurics-terrascan/en/latest/
.. _Terrascan config: https://docs.accurics.com/projects/accurics-terrascan/en/latest/usage/config_options/
.. _Scan Runner CLI: https://pypi.org/project/iac-scan-runner/
.. _iac-scan-runner: https://pypi.org/project/iac-scan-runner/
.. _PyPI: https://pypi.org/project/iac-scan-runner/
.. _TestPyPI: https://test.pypi.org/project/iac-scan-runner/
