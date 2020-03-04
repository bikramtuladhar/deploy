Prometheus tasks
================

Monitor a service
-----------------

If the ``prometheus-client-apache`` state file applies to the target, `Node Exporter <https://github.com/prometheus/node_exporter>`__ is served from port 80 (see ``pillar/private/prometheus_pillar.sls``), or the port set by the ``prometheus.client_port`` variable in the target's Pillar file. It is served from the domain configured in the server's ``/etc/apache2/sites-enabled/prometheus-client.conf`` file (see ``salt/prometheus-client-apache.sls``), and/or from the server's FQDN or IP address if the port isn't 80.

If the ``prometheus-client-nginx`` state file applies to the target, `Node Exporter <https://github.com/prometheus/node_exporter>`__ is served from port 9158 (see ``salt/nginx/prometheus-client``). It is served from the server's FQDN.

#. For a Hetzner server, set the ``prometheus.client_port`` variable in the target's Pillar file to ``7231``, and :doc:`re-deploy<deploy>` the service.

#. Check that Node Exporter is accessible and that its "Metrics" page displays metrics.

   For Apache, open, for example, http://prom-client.live.docs.opencontracting.uk0.bigv.io for a Bytemark server or http://95.217.76.74:7231 for a Hetzner server.

   For Nginx, open, for example, http://live.redash.opencontracting.uk0.bigv.io:9158.

   The username is ``prom``. The password is set by the ``prometheus.client_password`` variable in the ``pillar/private/prometheus_pillar.sls`` file.

#. If Node Exporter isn't accessible, edit the ``prometheus.client_port`` and/or ``prometheus.client_fqdn`` variables in the target's Pillar file as needed, and :doc:`re-deploy<deploy>` the service.

#. Add a job to ``salt/private/prometheus-server-monitor/conf-prometheus.yml``, following the same pattern as other jobs.

#. :doc:`Deploy<deploy>` the Prometheus service.

#. Check that the job is "UP" on Prometheus' `Targets <https://monitor.prometheus.open-contracting.org/targets>`__ page.

.. note::

   Bytemark assigns hostnames like ``<server>.<group>.opencontracting.uk0.bigv.io`` to its servers, and implements wildcard DNS for any subdomains. By default, Node Exporter is served from ``prom-client.<hostname>`` on port 80, which works for Bytemark servers without additional configuration. For Hetzner servers, additional configuration is needed. Instead of adding a DNS entry and setting the ``prometheus.client_fqdn`` variable, we simply set the ``prometheus.client_port`` variable and access Node Exporter by the server's IP address.