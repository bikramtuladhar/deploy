# URL that OCDS /validator proxies to
ocds_cove_backend: https://cove.live.cove.opencontracting.uk0.bigv.io
oc4ids_cove_backend: https://oc4ids.cove.live.opendataservices.coop
cove:
  # This is intended to be a *little* larger than uwsgi_harakiri.
  apache_on_docs_server_proxy_timeout: 1830
