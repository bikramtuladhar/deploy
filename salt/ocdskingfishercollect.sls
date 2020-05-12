{% from 'lib.sls' import createuser, apache %}

include:
  - apache

ocdskingfishercollect-prerequisites:
  apache_module.enabled:
    - names:
      - proxy
      - proxy_http
    - watch_in:
      - service: apache2
  pkg.installed:
    - pkgs:
      - supervisor
      - curl

{% set user = 'ocdskfs' %}
{% set userdir = '/home/' + user %}
{{ createuser(user, auth_keys_files=['kingfisher']) }}

{% set scrapyddir = userdir + '/scrapyd/' %}

{{ scrapyddir }}:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ scrapyddir }}requirements.txt:
  file.managed:
    - source: salt://ocdskingfishercollect/scrapyd-requirements.txt
    - user: {{ user }}
    - group: {{ user }}
    - mode: 0444
    - require:
      - file: {{ scrapyddir }}

{{ scrapyddir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ scrapyddir }}
    - requirements: {{ scrapyddir }}requirements.txt
    - require:
      - file: {{ scrapyddir }}requirements.txt

{{ scrapyddir }}dbs:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ scrapyddir }}eggs:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ scrapyddir }}logs:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ scrapyddir }}items:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ userdir }}/.scrapyd.conf:
  file.managed:
    - source: salt://ocdskingfishercollect/scrapyd.ini
    - template: jinja
    - context:
        scrapyddir: {{ scrapyddir }}

/etc/supervisor/conf.d/scrapyd.conf:
  file.managed:
    - source: salt://ocdskingfishercollect/supervisor.conf
    - template: jinja
    - context:
        scrapyddir: {{ scrapyddir }}
    - watch_in:
      - service: supervisor

supervisor:
  pkg.installed:
    - name: supervisor
  service.running:
    - name: supervisor
    - enable: True
    - reload: True

kfs-apache-password:
  cmd.run:
    - name: htpasswd -b -c {{ userdir }}/htpasswd scrape {{ pillar.ocdskingfishercollect.web.password }}
    - runas: {{ user }}
    - cwd: {{ userdir }}

{{ apache('ocdskingfisherscrape.conf',
    name='ocdskingfisherscrape.conf',
    servername='collect.kingfisher.open-contracting.org',
    serveraliases=['scrape.kingfisher.open-contracting.org']) }}

find {{ userdir }}/scrapyd/logs/ -type f -name "*.log" -exec sh -c 'if [ ! -f {}.stats ]; then result=$(tac {} | head -n99 | grep -m1 -B99 statscollectors | tac); if [ ! -z "$result" ]; then echo "$result" > {}.stats; fi; fi' \;:
  cron.present:
    - identifier: OCDS_KINGFISHER_SCRAPE_LOG_STATS
    - user: {{ user }}
    - minute: 0