Get started
===========

1. Install Salt
---------------

On macOS, using Homebrew, install Salt and Salt SSH with:

.. code-block:: bash

    brew install salt

If you encounter issues, try installing with pip:

.. code-block:: bash

    pip install salt salt-ssh

For other operating systems and package managers, see `this page <https://repo.saltstack.com/>`__ (or `this page <https://docs.saltstack.com/en/latest/topics/installation/index.html>`__) to install a recent version (2019 or later).

You must use Salt with Python 3. If your system package uses Python 2, install salt-ssh with pip into a Python 3 virtual environment.

2. Clone repositories
---------------------

You must first have access to three private repositories. Contact an owner of the open-contracting organization on GitHub for access. Then:

.. code-block:: bash

    git clone git@github.com:open-contracting/deploy.git
    git clone git@github.com:open-contracting/deploy-salt-private.git deploy/salt/private
    git clone git@github.com:open-contracting/deploy-pillar-private.git deploy/pillar/private
    git clone git@github.com:open-contracting/dogsbody-maintenance.git deploy/salt/maintenance

.. _add-public-key:

3. Add public key to remote servers
-----------------------------------

Add your public key to the relevant file in the ``salt/private/authorized_keys`` directory, e.g.:

.. code-block:: bash

    cat ~/.ssh/id_rsa.pub >> salt/private/authorized_keys/root_to_add
    git commit salt/private/authorized_keys/root_to_add -m "Add public key"
    git push origin master

Then, ask a colleague to deploy your public key to the relevant servers. For example:

.. code-block:: bash

    ./run.py '*' state.sls_id root_authorized_keys_add core

4. Configure Salt for non-root user
-----------------------------------

Unless your local user is the root user, run:

.. code-block:: bash

    ./script/setup

This script assumes your SSH keys are ``~/.ssh/id_rsa`` and ``~/.ssh/id_rsa.pub``.

You're now ready to :doc:`../deploy/deploy`.
