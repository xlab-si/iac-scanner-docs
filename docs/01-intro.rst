.. _Introduction:

************
Introduction
************

The **IaC Scanner** is an inspection service that aims to scan IaC (Infrastructure as Code) in order to find the
problems and security vulnerabilities, so that the users can improve their code.

The **IaC Scanner** supports the following logic - one IaC *scan* can consist of one or multiple IaC *checks*, which
are the results from tools that can analyze IaC and detect common IaC vulnerabilities.
These tools can be anything from linters and static code analysis tools (like `Pylint`_) to remote service checks (such
as `Snyk`_).

**IaC Scanner** currently includes the following tools and services:

- :ref:`IaC Scan Runner`: an IaC scan runner component that serves as an IaC inspector
- :ref:`IaC Scanner SaaS`: the Software as a Service edition that supports IaC scanning along with multi-tenancy and
  multi-user experience

.. _Pylint: https://www.pylint.org/
.. _Snyk: https://snyk.io/
