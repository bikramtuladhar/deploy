# This file defines various common macros.


#-----------------------------------------------------------------------
# createuser
#
# Our deployment policy is to run as much as possible as unprivileged users.
# Ideally each piece of work we do (which probably maps to a separate salt
# forumula) should have its own user defined.
# Therefore, most of our main salt formulas will begin by defining a user.
#-----------------------------------------------------------------------

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

{{ user }}_root_authorized_keys_remove:
  ssh_auth.absent:
   - user: {{ user }}
   - source: salt://private/authorized_keys/root_to_remove
   - require:
     - user: {{ user }}_user_exists

{% for auth_keys_file in auth_keys_files %}

{{ user }}_{{ auth_keys_file }}_authorized_keys_add:
  ssh_auth.present:
   - user: {{ user }}
   - source: salt://private/authorized_keys/{{ auth_keys_file }}_to_add
   - require:
     - user: {{ user }}_user_exists

{{ user }}_{{ auth_keys_file }}_authorized_keys_remove:
  ssh_auth.absent:
   - user: {{ user }}
   - source: salt://private/authorized_keys/{{ auth_keys_file }}_to_remove
   - require:
     - user: {{ user }}_user_exists

{% endfor %}

{% endmacro %}


#-----------------------------------------------------------------------
# apache
# Install the named conf file in the apache dir onto the server.
#-----------------------------------------------------------------------

{% macro apache(conffile, name='', extracontext='', socket_name='', servername='', serveraliases=[], https='') %}

{% if name == '' %}
{% set name=conffile %}
{% endif %}
{% if servername == '' %}
{% set servername=grains.fqdn %}
{% endif %}

# We always copy this .include file. For many sites it is empty. That is fine.
# But for sites we want to use SSL on, you need an .include file.
# And we want to avoid duplicating config between the X.conf and the X.conf.include file.
# So always copy the .include file, and then it is available to be used via an Include statement, whatever SSL mode is selected.
# (see salt/apache/opendataservices-website.conf for an example)
/etc/apache2/sites-available/{{ name }}.include:
  file.managed:
    - source: salt://apache/{{ conffile }}.include
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
        socket_name: {{ socket_name }}
        https: "{{ https }}"
        {{ extracontext | indent(8) }}


{% if https == 'yes' or https == 'force' or https == 'certonly' %}

# https-enabled config has two files: the main .conf file is just
# boilerplate from _common.conf, the service-specific config is in an
# Apache-included file <name>.conf.include.
#   Note 1, the include does not get linked into sites-enabled.
#   Note 2, ideally we would use a Jinja include to create a proper
#           standalone conf file, but that doesn't work in salt-ssh.

/etc/apache2/sites-available/{{ name }}:
  file.managed:
    - source: salt://apache/_common.conf
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
        socket_name: {{ socket_name }}
        includefile: {{ name }}.include
        servername: {{ servername }}
        serveraliases: {{ serveraliases|yaml }}
        https: "{{ https }}"
        {{ extracontext | indent(8) }}

{% set domainargs= "-d "+ " -d ".join([ servername ] + serveraliases ) %}

{{ servername }}_acquire_certs:
  cmd.run:
    - name: /etc/init.d/apache2 reload; letsencrypt certonly --non-interactive --no-self-upgrade --expand --email code@opendataservices.coop --agree-tos --webroot --webroot-path /var/www/html/ {{ domainargs }}
    - creates:
      - /etc/letsencrypt/live/{{ servername }}/cert.pem
      - /etc/letsencrypt/live/{{ servername }}/chain.pem
      - /etc/letsencrypt/live/{{ servername }}/fullchain.pem
      - /etc/letsencrypt/live/{{ servername }}/privkey.pem
    - require:
      - pkg: letsencrypt
      - file: /etc/apache2/sites-available/{{ name }}
      - file: /etc/apache2/sites-available/{{ name }}.include
      - file: /etc/apache2/sites-enabled/{{ name }}
      # The next line refers to something in salt/letsencrypt.sls
      - file: /var/www/html/.well-known/acme-challenge
    - watch_in:
      - service: apache2

{% else %}

# Render the config files with jinja and place them in sites-available
/etc/apache2/sites-available/{{ name }}:
  file.managed:
    - source: salt://apache/{{ conffile }}
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
        socket_name: {{ socket_name }}
        servername: {{ servername }}
        serveraliases: {{ serveraliases|yaml }}
        https: "{{ https }}"
        includefile: "/etc/apache2/sites-available/{{ name }}.include"
        {{ extracontext | indent(8) }}

{% endif %}

# Create a symlink from sites-enabled to enable the config
/etc/apache2/sites-enabled/{{ name }}:
  file.symlink:
    - target: /etc/apache2/sites-available/{{ name }}
    - require:
      - file: /etc/apache2/sites-available/{{ name }}
    - makedirs: True
    - watch_in:
      - service: apache2

{% endmacro %}


{% macro removeapache(name) %}

/etc/apache2/sites-available/{{ name }}:
  file.absent

/etc/apache2/sites-available/{{ name }}.include:
  file.absent

/etc/apache2/sites-enabled/{{ name }}:
  file.absent

{% endmacro %}


#-----------------------------------------------------------------------
# uwsgi
#-----------------------------------------------------------------------

{% macro uwsgi(conffile, name, port='', socket_name='', extracontext='') %}
# Render the file with jinja and place it in apps-available
/etc/uwsgi/apps-available/{{ name }}:
  file.managed:
    - source: salt://uwsgi/{{ conffile }}
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: uwsgi
    - context:
        socket_name: {{ socket_name }}
        port: {{ port }}
        {{ extracontext | indent(8) }}

# Create a symlink from apps-enabled to enable the config
/etc/uwsgi/apps-enabled/{{ name }}:
  file.symlink:
    - target: /etc/uwsgi/apps-available/{{ name }}
    - require:
      - file: /etc/uwsgi/apps-available/{{ name }}
    - makedirs: True
    - watch_in:
      - service: uwsgi

# Add a fail2ban jail for this uwsgi instance
# /etc/fail2ban/jail.d/uwsgi-{{ name }}.conf:
#   file.managed:
#     - source: salt://fail2ban/jail.d/uwsgi.conf
#     - template: jinja
#     - makedirs: True
#     - watch_in:
#       - service: fail2ban
#     - context:
#         name: {{ name }}
#         port: {{ port }}

{% endmacro %}


{% macro removeuwsgi(name) %}

/etc/uwsgi/apps-available/{{ name }}:
  file.absent

/etc/uwsgi/apps-enabled/{{ name }}:
  file.absent

{% endmacro %}


# app: override the DJANGO_SETTINGS_MODULE set in the Django project's manage.py file
{% macro django(name, user, giturl, branch, djangodir, pip_require, app=None, compilemessages=True) %}
{{ giturl }}{{ djangodir }}:
  git.latest:
    - name: {{ giturl }}
    - rev: {{ branch }}
    - target: {{ djangodir }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git
    - watch_in:
      - service: uwsgi

# We have seen different permissions on different servers and we have seen bugs arise due to problems with the permissions.
# Make sure the user and permissions are set correctly for the media folder and all it's contents!
# (This in itself won't make sure permissions are correct on new files, but it will sort any existing problems)
{{ djangodir }}media:
  file.directory:
    - name: {{ djangodir }}media
    - user: {{ user }}
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - mode

# Install the latest version of pip first
# This is necessary to download linux wheels, which avoids building C code
{{ djangodir }}.ve/-pip:
  virtualenv.managed:
    - name: {{ djangodir }}.ve/
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - pip_pkgs: pip==8.1.2
    - require:
      - {{ pip_require }}
      - git: {{ giturl }}{{ djangodir }}

# Then install the rest of our requirements
{{ djangodir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ djangodir }}requirements.txt
    - require:
      - virtualenv: {{ djangodir }}.ve/-pip
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

migrate-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; {% if app %}DJANGO_SETTINGS_MODULE={{ app }}.settings {% endif %}python manage.py migrate --noinput
    - runas: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

{% if compilemessages %}
compilemessages-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; {% if app %}DJANGO_SETTINGS_MODULE={{ app }}.settings {% endif %}python manage.py compilemessages
    - runas: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}
{% endif %}

collectstatic-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; {% if app %}DJANGO_SETTINGS_MODULE={{ app }}.settings {% endif %}python manage.py collectstatic --noinput
    - runas: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

{{ djangodir }}static/:
  file.directory:
    - file_mode: 644
    - dir_mode: 755
    - recurse:
      - mode
    - require:
      - cmd: collectstatic-{{name}}
    - user: {{ user }}
    - group: {{ user }}

{{ djangodir }}:
  file.directory:
    - dir_mode: 755
    - require:
      - cmd: collectstatic-{{name}}
    - user: {{ user }}
    - group: {{ user }}
{% endmacro %}
