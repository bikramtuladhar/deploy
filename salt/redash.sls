{% from 'lib.sls' import apache %}

include:
  - docker
  - apache-proxy

# =================================================================================================
# See https://ocdsdeploy.readthedocs.io/en/latest/deploy/redash.html for installation instructions.
# =================================================================================================

redash_prepackages:
  pkg.installed:
    - pkgs:
      - pwgen
      - postgresql-client-10

/opt/redash:
  file.directory:
    - user: root
    - group: root
    - makedirs: True

{{ apache('redash', servername=pillar.apache.servername, https=pillar.apache.https) }}
