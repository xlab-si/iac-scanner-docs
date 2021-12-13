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
| `/checks/{check_name}/enable`_            | Enable check for running          |
+-------------------------------------------+-----------------------------------+
| `/checks/{check_name}/disable`_           | Disable check for running         |
+-------------------------------------------+-----------------------------------+
| `/checks/{check_name}/configure`_         | Configure check                   |
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

.. _/checks/{check_name}/enable:

.. http:patch:: /checks/{check_name}/enable

    IaC checks can be enabled (can be used for scanning) or disabled (cannot be used for scanning).
    Most of the local checks are enabled by default and some of them that are advanced, take longer time or require
    additional configuration are disabled and have to be enabled before the scanning.
    This endpoint can be used to enable a specific IaC check (selected by the *check_name* parameter), which means that
    it will become available for running within IaC scans.

    **Example request**:

    .. tabs::

        .. code-tab:: bash

            $ curl -X 'PATCH' 'http://127.0.0.1:8000/checks/snyk/enable'

        .. code-tab:: python

            import requests
            URL = 'http://127.0.0.1:8000/checks/snyk/enable'
            response = requests.patch(URL)
            print(response.json())

    **Example response**:

    .. sourcecode:: json

        "Check: snyk is now enabled and available to use."

    :param string check_name: check that you want to enable for running
    :statuscode 200: Successful Response
    :statuscode 400: Bad Request
    :statuscode 422: Validation Error

------------------------------------------------------------------------------------------------------------------------

.. _/checks/{check_name}/disable:

.. http:patch:: /checks/{check_name}/disable

    This endpoint can be used to disable a specific IaC check (selected by the *check_name* parameter), which means
    that it will become unavailable for running within IaC scans.

    **Example request**:

    .. tabs::

        .. code-tab:: bash

            $ curl -X 'PATCH' 'http://127.0.0.1:8000/checks/pylint/disable'

        .. code-tab:: python

            import requests
            URL = 'http://127.0.0.1:8000/checks/pylint/enable'
            response = requests.patch(URL)
            print(response.json())

    **Example response**:

    .. sourcecode:: json

        "Check: pylint is now disabled and cannot be used."

    :param string check_name: check that you want to disable for running
    :statuscode 200: Successful Response
    :statuscode 400: Bad Request
    :statuscode 422: Validation Error

------------------------------------------------------------------------------------------------------------------------

.. _/checks/{check_name}/configure:

.. http:patch:: /checks/{check_name}/configure

    This endpoint is used to configure a specific IaC check (selected by the *check_name* parameter).
    Most IaC checks do not need configuration as they already use their default settings.
    However, some of them - especially the remote service checks (such as `Snyk`_) require to be configured before
    using them within IaC scans.
    Some checks will have to be enabled before they can be configured.
    The configuration of IaC check takes two optional `multipart`_ request body parameters - *config_file* and *secret*.
    The former (*config_file*) can be used to pass a check configuration file (which is supported by almost every
    check) that is specific to every check and will override the default check settings.
    The latter (*secret*) is meant for passing sensitive data such as passwords, API keys, tokens, etc.
    These secrets are often used to configure the remote service checks - usually to authenticate the user via some
    token that has been generated in the remote service user profile settings.
    Some IaC checks support both the aforementioned request body parameters and some support one of them or none.
    The API will warn you in case of any configuration problems.

    **Example request**:

    .. tabs::

        .. code-tab:: bash

            $ curl -X 'PATCH' 'http://127.0.0.1:8000/checks/sonar-scanner/configure' -H 'Content-Type: multipart/form-data' -F 'config_file=@sonar-project.properties;type=text/plain' -F 'secret=56bf-example-token-f007'

        .. code-tab:: python

            import requests
            URL = 'http://127.0.0.1:8000/checks/sonar-scanner/configure'
            multipart_form_data = {
                'config_file': ('sonar-project.properties', open('/path/to/sonar-project.properties', 'rb')),
                'secret': (None, '56bf-example-token-f007')
            }
            response = requests.patch(URL, files=multipart_form_data)
            print(response.json())

    **Example response**:

    .. sourcecode:: json

        "Check: sonar-scanner has been configured successfully."

    :param string check_name: check that you want to configure before scanning
    :form config_file: optional check configuration file
    :form secret: optional secret for configuration (password, API token, etc.)
    :statuscode 200: Successful Response
    :statuscode 400: Bad Request
    :statuscode 422: Validation Error

.. Warning:: Be careful not to expose your secrets directly in your IaC.

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
| IaC Check                     | Target IaC entity          | Enabled (by default)       | Needs configuration        |
+===============================+============================+============================+============================+
| `Ansible Lint`_               | Ansible                    | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `TFLint`_                     | Terraform                  | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `tfsec`_                      | Terraform                  | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `Terrascan`_                  | Terraform                  | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `yamllint`_                   | YAML                       | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `Pylint`_                     | Python                     | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `Bandit`_                     | Python                     | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `Safety`_                     | Python packages            | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `Gitleaks`_                   | Git repositories           | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `git-secrets`_                | Git repositories           | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `Markdown lint`_              | Markdown files             | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `hadolint`_                   | Docker                     | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `Gixy`_                       | Nginx configuration        | yes                        | no                         |
+-------------------------------+----------------------------+----------------------------+----------------------------+
| `ShellCheck`_                 | Shell scripts              | yes                        | no                         |
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

.. _yamllint:

yamllint
########

**yamllint** is a linter for YAML files that checks for syntax validity, key repetition and cosmetic problems such as
lines length, trailing spaces, indentation, etc. (see `yamllint check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``yamllint``                    |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `yamllint docs`_                |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional YAML configuration file (see `yamllint config`_).
        You can also skip the configuration put the configuration file to the root of your IaC package.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _Pylint:

Pylint
######

**Pylint** is a Python static code analysis tool that checks for errors in Python code, tries to enforce a coding
standard and looks for code smells (see `Pylint check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``pylint``                      |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `Pylint docs`_                  |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional TOML configuration file (see `Pylint config`_).
        You can also skip this configuration and put the config file (it could be called ``.pylintrc`` or there are
        numerous other options).

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _Bandit:

Bandit
######

**Bandit** is a tool designed to find common security issues in Python code (see `Bandit check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``bandit``                      |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `Bandit docs`_                  |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional YAML or TOML configuration file (see `Bandit config`_).

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _Safety:

Safety
######

**Safety** is a is a `PyUp`_ CLI tool that checks your installed Python dependencies for known security vulnerabilities
(see `PyUp Safety check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``pyup-safety``                 |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `PyUp Safety docs`_             |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Not supported.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _Gitleaks:

Gitleaks
########

**Gitleaks** is a SAST tool for detecting hardcoded secrets like passwords, API keys, and tokens in Git repos
(see `Gitleaks check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``git-leaks``                   |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `Gitleaks docs`_                |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional TOML configuration file (see `Gitleaks config`_).

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _git-secrets:

git-secrets
###########

**git-secrets** is a tool that prevents you from committing secrets and credentials into Git repositories
(see `git-secrets check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``git-secrets``                 |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `git-secrets docs`_             |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Not supported.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _Markdown lint:

Markdown lint
#############

**Markdown lint** is a tool to check markdown files and flag style issues (see `Markdown lint check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``markdown-lint``               |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `Markdown lint docs`_           |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional ``.rc`` or ``.mdlrc`` configuration file (see `Markdown lint config`_).
        You can also skip the configuration put the configuration file named ``.mdlrc`` to the root of your IaC package.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _hadolint:

hadolint
########

**hadolint** is a Dockerfile linter (see `hadolint check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``hadolint``                    |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `hadolint docs`_                |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional YAML configuration file (see `hadolint config`_).
        You can also skip this configuration and put the configuration file (with the name ``.hadolint.yaml`` or
        ``.hadolint.yml``) to the root of your IaC package.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _Gixy:

Gixy
####

**Gixy** is a tool to analyze Nginx configuration (see `Gixy check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``gixy``                        |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `Gixy docs`_                    |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Accepts an optional ``.conf`` configuration file (see `Gixy config`_).

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _ShellCheck:

ShellCheck
##########

**stylelint** is a static analysis tool for shell scripts (see `ShellCheck check`_).

+-------------------------+---------------------------------+
| Check ID (from the API) | ``shellcheck``                  |
+-------------------------+---------------------------------+
| Enabled (by default)    | yes                             |
+-------------------------+---------------------------------+
| Configured (by default) | yes                             |
+-------------------------+---------------------------------+
| Documentation           | `ShellCheck docs`_              |
+-------------------------+---------------------------------+

.. admonition:: Configuration options for `/checks/{check_name}/configure`_ API endpoint

    :Config file:

        Not supported.

    :Secret:

        Not supported.

------------------------------------------------------------------------------------------------------------------------

.. _IaC Scan Runner CLI:

===
CLI
===

The **IaC Scan Runner CLI** enables easier setup of IaC Scan Runner in console environments.

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

Commands
########

``iac-scan-runner`` currently allows users to execute the following shell commands:

+-----------------------------+------------------------------------------------+
| CLI command                 | Purpose and description                        |
+=============================+================================================+
| ``iac-scan-runner openapi`` | print `OpenAPI Specification`_                 |
+-----------------------------+------------------------------------------------+
| ``iac-scan-runner install`` | install the IaC Scan Runner prerequisites      |
+-----------------------------+------------------------------------------------+
| ``iac-scan-runner run``     | run the IaC Scan Runner REST API               |
+-----------------------------+------------------------------------------------+

.. tip:: All the CLI commands are equipped with ``-h/--help`` option to help you.

------------------------------------------------------------------------------------------------------------------------

.. click:: iac_scan_runner.cli:typer_click_object
    :prog: iac-scan-runner
    :nested: full

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
.. _yamllint check: https://github.com/adrienverge/yamllint/
.. _yamllint docs: https://yamllint.readthedocs.io/en/latest/
.. _yamllint config: https://yamllint.readthedocs.io/en/latest/configuration.html
.. _Pylint check: https://github.com/PyCQA/pylint/
.. _Pylint docs: http://pylint.pycqa.org/en/latest/
.. _Pylint config: http://pylint.pycqa.org/en/latest/user_guide/run.html#command-line-options
.. _Bandit check: https://github.com/PyCQA/bandit/
.. _Bandit docs: https://bandit.readthedocs.io/en/latest/
.. _Bandit config: https://github.com/PyCQA/bandit/
.. _PyUp: https://pyup.io/
.. _PyUp Safety check: https://github.com/pyupio/safety/
.. _PyUp Safety docs: https://pyup.io/safety/
.. _PyUp Safety config: https://github.com/pyupio/safety/
.. _Gitleaks check: https://github.com/zricethezav/gitleaks/
.. _Gitleaks docs: https://docs.securecodebox.io/docs/scanners/gitleaks/
.. _Gitleaks config: https://github.com/zricethezav/gitleaks#configuration
.. _git-secrets check: https://github.com/awslabs/git-secrets/
.. _git-secrets docs: https://github.com/awslabs/git-secrets/
.. _Markdown lint check: https://github.com/markdownlint/markdownlint/
.. _Markdown lint docs: https://github.com/markdownlint/markdownlint
.. _Markdown lint config: https://github.com/markdownlint/markdownlint/blob/master/docs/configuration.md
.. _hadolint check: https://github.com/hadolint/hadolint/
.. _hadolint docs: https://github.com/hadolint/hadolint/blob/master/docs/INTEGRATION.md
.. _hadolint config: https://github.com/hadolint/hadolint#configure
.. _Gixy check: https://github.com/yandex/gixy/
.. _Gixy docs: https://github.com/yandex/gixy/
.. _Gixy config: https://github.com/yandex/gixy/
.. _ShellCheck check: https://github.com/koalaman/shellcheck/
.. _ShellCheck docs: https://github.com/koalaman/shellcheck/wiki
.. _ShellCheck config: https://github.com/koalaman/shellcheck/
.. _Scan Runner CLI: https://pypi.org/project/iac-scan-runner/
.. _iac-scan-runner: https://pypi.org/project/iac-scan-runner/
.. _PyPI: https://pypi.org/project/iac-scan-runner/
.. _TestPyPI: https://test.pypi.org/project/iac-scan-runner/
