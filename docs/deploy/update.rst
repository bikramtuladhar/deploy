Update server configurations
============================

Change server name
------------------

If the virtual host uses HTTPS, you will need to acquire SSL certificates for the new server name and remove the SSL certificates for the old server name.

#. Change the ``ServerName``
#. In the relevant Pillar file, change ``https`` to ``certonly``
#. :doc:`Deploy the service<deploy>`
#. In the relevant Pillar file, change ``https`` to ``force`` or ``both``
#. Remove the old SSL certificates, for example:

   .. code-block:: bash

      salt-ssh 'ocds-docs-staging' file.remove /etc/letsencrypt/live/dev.standard.open-contracting.org

To check for old SSL certificates that were previously not removed, run:

.. code-block:: bash

   salt-ssh '*' cmd.run 'ls /etc/letsencrypt/live'

.. _remove-content:

Remove content
--------------

If you delete a file, service, package, user, authorized key, Apache module, or virtual host from a file, it will not be removed from the server. To remove it, after you :doc:`deploy<deploy>`:

.. _delete-authorized_key:

Delete an authorized key
~~~~~~~~~~~~~~~~~~~~~~~~

#. Cut it from ``salt/private/authorized_keys/root_to_add``
#. Paste it into ``salt/private/authorized_keys/root_to_remove``
#. Run:

   .. code-block:: bash

      salt-ssh '*' state.sls_id root_authorized_keys_add core
      salt-ssh '*' state.sls_id root_authorized_keys_remove core

#. Delete it from ``salt/private/authorized_keys/root_to_remove``

Delete a file
~~~~~~~~~~~~~

Run, for example:

.. code-block:: bash

   salt-ssh 'ocds-docs-staging' file.remove /path/to/file_to_remove

Delete a cron job
~~~~~~~~~~~~~~~~~

#. Change ``cron.present`` to ``cron.absent`` in the Salt state
#. Delete the Salt state

Delete a service
~~~~~~~~~~~~~~~~

`Stop <https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.upstart_service.html#salt.modules.upstart_service.stop>`__ and `disable <https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.upstart_service.html#salt.modules.upstart_service.disable>`__ the service.

To stop and disable the ``icinga2`` service on the ``ocds-docs-staging`` target, for example:

.. code-block:: bash

   salt-ssh 'ocds-docs-staging' service.stop icinga2
   salt-ssh 'ocds-docs-staging' service.disable icinga2

If you deleted the ``uwsgi`` service, also run, for example:

.. code-block:: bash

   salt-ssh 'cove-live-ocds-3' file.remove /etc/uwsgi/apps-available/cove.ini
   salt-ssh 'cove-live-ocds-3' file.remove /etc/uwsgi/apps-enabled/cove.ini

Delete a package
~~~~~~~~~~~~~~~~

`Remove a package and its configuration files <https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.aptpkg.html#salt.modules.aptpkg.purge>`__, and `remove any of its dependencies that are no longer needed <https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.aptpkg.html#salt.modules.aptpkg.autoremove>`__.

To scrub Icinga-related packages from the ``ocds-docs-staging`` target, for example:

.. code-block:: bash

   salt-ssh 'ocds-docs-staging' pkg.purge icinga2,nagios-plugins,nagios-plugins-contrib
   salt-ssh 'ocds-docs-staging' pkg.autoremove list_only=True
   salt-ssh 'ocds-docs-staging' pkg.autoremove purge=True

Then, login to the server and check for and delete any remaining packages, files or directories relating to the package, for example:

.. code-block:: bash

   dpkg -l | grep icinga
   dpkg -l | grep nagios
   ls /etc/icinga2
   ls /usr/lib/nagios

Delete an Apache module
~~~~~~~~~~~~~~~~~~~~~~~

#. Add a temporary Salt ID, for example:

   .. code-block:: none

      headers:
          apache_module.disabled

#. Deploy the relevant service, for example:

   .. code-block:: bash

      salt-ssh 'toucan' state.apply

#. Remove the temporary salt ID

Delete a virtual host
~~~~~~~~~~~~~~~~~~~~~

Run, for example:

.. code-block:: bash

   salt-ssh 'cove-ocds-live-2' file.remove /etc/apache2/sites-enabled/cove.conf
   salt-ssh 'cove-ocds-live-2' file.remove /etc/apache2/sites-available/cove.conf
   salt-ssh 'cove-ocds-live-2' file.remove /etc/apache2/sites-available/cove.conf.include

You might also delete the SSL certificates as when :ref:`changing server name<change-server-name>`.