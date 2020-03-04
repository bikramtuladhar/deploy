Troubleshoot
============

.. _watch-salt-activity:

Watch Salt activity
-------------------

If you want to check whether a deployment is simply slow or actually stalled, perform these steps:

#. Find the server's IP or fully-qualified domain name in the roster:

   .. code-block:: bash

      cat salt-config/roster

#. Open a secondary terminal to connect to the server as root, for example:

   .. code-block:: bash

      ssh root@live.docs.opencontracting.uk0.bigv.io

#. Watch the processes on the server:

   .. code-block:: bash

      watch -n 1 pstree

Then, once the deployment is done:

#. Stop watching the processes, e.g. with ``Ctrl-C``
#. Disconnect from the server, e.g. with ``Ctrl-D``

Avoid Pillar gotchas
--------------------

-  If unquoted, ``yes``, ``no``, ``true`` and ``false`` are parsed as booleans. Use quotes to parse as strings.
-  A blank value is parsed as ``None``. Use the empty string ``''`` to parse as a string.
-  Below, if ``a`` is equal to an empty string, then ``b`` will be ``None``:

   .. code-block:: none

      {% set extracontext %}
      b: {{ a }}
      {% endset %}

   Instead, surround it in quotes:

   .. code-block:: none

      {% set extracontext %}
      b: "{{ a }}"
      {% endset %}

Check history
-------------

If you don't understand why a configuration exists, it's useful to check its history.

The files in this repository were originally in the `opendataservices-deploy <https://github.com/OpenDataServices/opendataservices-deploy>`__ repository. You can `browse <https://github.com/OpenDataServices/opendataservices-deploy/tree/7a5baff013b888c030df8366b3de45aae3e12f9e>`__ that repository from before the switchover (August 5, 2019). That repository was itself re-organized at different times. You can browse `before moving content from *.conf to *.conf.include <https://github.com/OpenDataServices/opendataservices-deploy/tree/4dbea5122e1fc01221c8d051efc99836cef98ccb>`__ (June 5, 2019).