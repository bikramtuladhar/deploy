# Defines common macros.

{% macro configurefirewall(setting_name, setting_value="yes") %}
configure firewall setting {{ setting_name }}:
  file.replace:
    - name:  /home/sysadmin-tools/firewall-settings.local
    - pattern: "{{ setting_name }}=.*"
    - repl: "{{ setting_name }}=\"{{setting_value}}\""
    - append_if_not_found: True
    - backup: ""
{% endmacro %}


# Our policy is to run as much as possible as unprivileged users. Therefore, most states start by creating a user.
{% macro createuser(user, auth_keys_files=[]) %}

{{ user }}_user_exists:
  user.present:
    - name: {{ user }}
    - home: /home/{{ user }}
    - order: 1
    - shell: /bin/bash

{{ user }}_root_authorized_keys_add:
  ssh_auth.present:
    - user: {{ user }}
    - source: salt://private/authorized_keys/root_to_add
    - require:
      - user: {{ user }}_user_exists

{% for auth_keys_file in auth_keys_files %}

{{ user }}_{{ auth_keys_file }}_authorized_keys_add:
  ssh_auth.present:
    - user: {{ user }}
    - source: salt://private/authorized_keys/{{ auth_keys_file }}_to_add
    - require:
      - user: {{ user }}_user_exists

{% endfor %}

{% endmacro %}


# It is safe to use `[]` as a default value, because the default value is never mutated.
{% macro apache(conffile, name='', servername='', serveraliases=[], https='', extracontext='', ports=[]) %}

{% if name == '' %}
    {% set name = conffile %}
{% endif %}

{% if servername == '' %}
    {% set servername = grains.fqdn %}
{% endif %}

{% if ports == [] %}
    {% if https == 'force' %}
        {% set ports = [80, 443] %}
    {% else %} {# https == 'certonly', used to serve /.well-known/acme-challenge over HTTP, or turned off #}
        {% set ports = [80] %}
    {% endif %}
{% endif %}

/etc/apache2/sites-available/{{ name }}.conf.include:
  file.managed:
    - source: salt://apache/{{ conffile }}.conf.include
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
        https: "{{ https }}"
        {{ extracontext|indent(8) }}

/etc/apache2/sites-available/{{ name }}.conf:
  file.managed:
    - source: salt://apache/_common.conf
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
        includefile: /etc/apache2/sites-available/{{ name }}.conf.include
        servername: {{ servername }}
        serveraliases: {{ serveraliases|yaml }}
        https: "{{ https }}"
        ports: {{ ports|yaml }}
        {{ extracontext|indent(8) }}
    - require:
      - file: /etc/apache2/sites-available/{{ name }}.conf.include

{% if https == 'force' or https == 'certonly' %}

{% set domainargs = "-d " + " -d ".join([servername] + serveraliases) %}

{{ servername }}_acquire_certs:
  cmd.run:
    - name: /etc/init.d/apache2 reload; letsencrypt certonly --non-interactive --no-self-upgrade --expand --email sysadmin@open-contracting.org --agree-tos --webroot --webroot-path /var/www/html/ {{ domainargs }}
    - creates:
      - /etc/letsencrypt/live/{{ servername }}/cert.pem
      - /etc/letsencrypt/live/{{ servername }}/chain.pem
      - /etc/letsencrypt/live/{{ servername }}/fullchain.pem
      - /etc/letsencrypt/live/{{ servername }}/privkey.pem
    - require:
      - pkg: letsencrypt
      - file: /etc/apache2/sites-available/{{ name }}.conf
      - file: /etc/apache2/sites-available/{{ name }}.conf.include
      - file: /etc/apache2/sites-enabled/{{ name }}.conf
      # The next line refers to something in salt/letsencrypt.sls
      - file: /var/www/html/.well-known/acme-challenge
    - watch_in:
      - service: apache2

{% endif %}

/etc/apache2/sites-enabled/{{ name }}.conf:
  file.symlink:
    - target: /etc/apache2/sites-available/{{ name }}.conf
    - require:
      - file: /etc/apache2/sites-available/{{ name }}.conf
    - makedirs: True
    - watch_in:
      - service: apache2

{% endmacro %}


{% macro uwsgi(service, name='', port='', appdir='') %}
# Service indicates which config file to use from salt/uwsgi/configs.

{% if name == '' %}
    {% set name = service %}
{% endif %}

/etc/uwsgi/apps-available/{{ name }}.ini:
  file.managed:
    - source: salt://uwsgi/configs/{{ service }}.ini
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: uwsgi
    - context:
        port: {{ port }}
        appdir: {{ appdir }}

/etc/uwsgi/apps-enabled/{{ name }}.ini:
  file.symlink:
    - target: /etc/uwsgi/apps-available/{{ name }}.ini
    - require:
      - file: /etc/uwsgi/apps-available/{{ name }}.ini
    - makedirs: True
    - watch_in:
      - service: uwsgi

{% endmacro %}
