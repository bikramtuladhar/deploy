{% from 'lib.sls' import createuser,  apache %}

include:
  - apache
  - apache-proxy

{% set user = 'prometheus-alertmanager' %}
{{ createuser(user) }}

## Get binary

get_prometheus_alertmanager:
  cmd.run:
    - name: curl -L https://github.com/prometheus/alertmanager/releases/download/v{{ pillar.prometheus_alertmanager.version }}/alertmanager-{{ pillar.prometheus_alertmanager.version }}.linux-amd64.tar.gz -o /home/{{ user }}/alertmanager-{{ pillar.prometheus_alertmanager.version }}.tar.gz
    - creates: /home/{{ user }}/alertmanager-{{ pillar.prometheus_alertmanager.version }}.tar.gz
    - requires:
      - user: {{ user }}_user_exists

extract_prometheus_alertmanager:
  cmd.run:
    - name: tar xvzf alertmanager-{{ pillar.prometheus_alertmanager.version }}.tar.gz
    - creates: /home/{{ user }}/alertmanager-{{ pillar.prometheus_alertmanager.version }}.linux-amd64/alertmanager
    - cwd: /home/{{ user }}/
    - requires:
      - cmd.get_prometheus_alertmanager

## Configure

/home/{{ user }}/conf-alertmanager.yml:
  file.managed:
    - source: salt://private/prometheus-server-alertmanager/conf-alertmanager.yml
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

## Data

/home/{{ user }}/data:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True
    - requires:
      - user: {{ user }}_user_exists

## Start service

/etc/systemd/system/prometheus-alertmanager.service:
  file.managed:
    - source: salt://prometheus-server-alertmanager/prometheus-alertmanager.service
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

prometheus-alertmanager:
  service.running:
    - enable: True
    - requires:
      - cmd: extract_prometheus_alertmanager
    # Make sure service restarts if any config changes
    - watch:
      - file: /home/{{ user }}/conf-alertmanager.yml
      - file: /etc/systemd/system/prometheus-alertmanager.service

## Apache reverse proxy with password for security

{{ user }}-apache-password:
  cmd.run:
    - name: htpasswd -b -c /home/{{ user }}/htpasswd prom {{ pillar.prometheus_alertmanager.password }}
    - runas: {{ user }}
    - cwd: /home/{{ user }}

{{ apache('prometheus-alertmanager',
    servername=pillar.prometheus_alertmanager.fqdn,
    https=pillar.prometheus_alertmanager.https,
    extracontext='user: ' + user) }}
