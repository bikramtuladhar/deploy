Update server configurations
============================

1. Update private templates
---------------------------

If you add, remove or rename a file or variable in ``pillar/private`` or ``salt/private``, replicate the changes in ``pillar/private-templates`` or ``salt/private-templates``.

This allows others to use this repository to, for example, deploy Kingfisher to their own servers.

2. Test changes
---------------

To preview what is going to change, use `test=True <https://docs.saltstack.com/en/latest/ref/states/testing.html>`__, for example:

.. code-block:: bash

   salt-ssh 'ocds-docs-live' state.apply test=True

To preview changes to a Pillar file, run, for example:

.. code-block:: bash

   salt-ssh 'ocds-docs-live' pillar.items

To compare Jinja2 output after refactoring but before committing, use ``script/diff`` to compare a full state or one SLS file, for example:

.. code-block:: bash

   ./script/diff ocds-docs-staging
   ./script/diff ocds-docs-staging ocds-docs-common

If you get the error, ``An Exception occurred while executing state.show_highstate: 'list' object has no attribute 'values'``, run ``state.apply test=True`` as above. You might have conflicting IDs.

Using a testing virtual host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To test changes to the Apache files for the :doc:`../reference/docs` (for example, to test new redirects or proxy settings):

#. Make changes inside ``{% if testing %}`` blocks in the config files
#. :doc:`Deploy<../deploy/deploy>` the OCDS Documentation
#. To test manually, visit the testing version of the `live website <http://testing.live.standard.open-contracting.org/>`__ or `staging website <http://testing.staging.standard.open-contracting.org/>`__
#. To test automatically, run (using the fish shell):

.. code-block:: bash

   pip install -r requirements.txt
   env FQDN=testing.live.standard.open-contracting.org pytest

Update the tests if you changed the behavior of the Apache files.

Once satisfied, move the changes outside ``{% if testing  %}`` blocks. After deployment, the tests should pass if ``FQDN`` is omitted or set to standard.open-contracting.org.

Using a virtual machine
~~~~~~~~~~~~~~~~~~~~~~~

#. `Create a virtual machine <https://docs.saltstack.com/en/getstarted/ssh/system.html>`__
#. Get the virtual machine's IP address

   - If using VirtualBox, run (replacing ``VMNAME``):

     .. code-block:: bash

        VBoxManage guestproperty get VMNAME "/VirtualBox/GuestInfo/Net/0/V4/IP"

#. Update the relevant target in ``salt-config/roster`` to point to the virtual machine's IP address
#. In the relevant Pillar file, change ``https`` to ``no``, if certbot is used to enable HTTPS
#. Edit ``/etc/hosts`` to map the virtual machine's IP address to the service's hostname
#. Deploy to the virtual machine and test

Note that Python errors that occur on the virtual machine might still be reported to Sentry. The ``server_name`` tag in any error reports is expected to be different, but the error reports might still confuse other developers who don't know to check that tag.

3. Review code
--------------

For context, for other repositories, work is done on a branch and tested on a local machine before a pull request is made, which is then tested on Travis CI, reviewed and approved before merging.

However, for this repository, in some cases, it's impossible to test changes to server configurations, for example: if SSL certificates are involved (because certbot can't verify a virtual machine), or if external services like Travis are involved. In other cases, it's too much effort to setup a test environment in which to test changes.

In such cases, the same process is followed as in other repositories, but without the benefit of tests.

In entirely uncontroversial or time-sensitive cases, work is done on the ``master`` branch, deployed to servers, and committed to the ``master`` branch once successful. In cases where the changes require trial and error, the general approach is discussed in a GitHub issue, and then work is done on the ``master`` branch as above. Developers can always request informal reviews from colleagues.

Take extra care when making larger changes or when making changes to `higher-priority apps <https://github.com/open-contracting/standard-maintenance-scripts/blob/master/badges.md>`__.

.. _change-server-name:

Change server name
------------------

If the virtual host uses HTTPS, you will need to acquire SSL certificates for the new server name and remove the SSL certificates for the old server name.

#. Change the ``ServerName``
#. In the relevant Pillar file, change ``https`` to ``certonly``
#. :doc:`Deploy the service<../deploy/deploy>`
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

If you delete a file, service, package, user, authorized key, Apache module, or virtual host from a file, it will not be removed from the server. To remove it, after you :doc:`deploy<../deploy/deploy>`:

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

Track upstream
--------------

The files in this repository were originally in the `opendataservices-deploy <https://github.com/OpenDataServices/opendataservices-deploy>`__ repository. Some common files might have improvements in the original repository. To check for updates, run:

.. code-block:: bash

   git clone git@github.com:OpenDataServices/opendataservices-deploy.git
   cd opendataservices-deploy
   git log --name-status setup_for_non_root.sh updateToMaster.sh Saltfile pillar/common_pillar.sls salt-config/master salt/apache.sls salt/apache/000-default.conf salt/apache/000-default.conf.include salt/apache/_common.conf salt/apache/cove.conf salt/apache/cove.conf.include salt/apache/prometheus-client.conf salt/apache/prometheus-client.conf.include salt/apache/robots_dev.txt salt/apt/10periodic salt/apt/50unattended-upgrades salt/core.sls salt/cove.sls salt/letsencrypt.sls salt/lib.sls salt/nginx/redash salt/prometheus-client-apache.sls salt/prometheus-client/prometheus-node-exporter.service salt/system/ocdskingfisher_motd salt/uwsgi.sls salt/uwsgi/cove.ini

-  ``setup_for_non_root.sh`` corresponds to ``script/setup``
-  ``updateToMaster.sh`` corresponds to ``script/update``
-  ``salt-config/roster``, ``pillar/top.sls`` and ``salt/top.sls`` are common files, but are unlikely to contain improvements

This repository has all improvements up to September 30, 2019.