user: ocdskit-web
name: ocdskit-web
apache:
  https: force
  servername: toucan.open-contracting.org
git:
  url: https://github.com/open-contracting/toucan.git
django:
  app: ocdstoucan
  env:
    ALLOWED_HOSTS: toucan.open-contracting.org
    GOOGLE_ANALYTICS_ID: UA-35677147-3

uwsgi:
  limit-as: 1536
  max-requests: 1024
  reload-on-as: 250
