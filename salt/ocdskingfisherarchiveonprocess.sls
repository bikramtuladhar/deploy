{% from 'lib.sls' import createuser %}

{% set user = 'archive' %}
{{ createuser(user) }}

{% for file in ['id_rsa', 'id_rsa.pub'] %}
/home/{{ user }}/.ssh/{{ file }}:
  file.managed:
    - source: salt://private/kingfisher-archive/{{ file }}
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}
    - mode: 600
    - require:
       - user: {{ user }}_user_exists
{% endfor %}

{% set giturl = 'https://github.com/open-contracting/kingfisher-archive.git' %}
{% set userdir = '/home/' + user %}
{% set ocdskingfisherdir = userdir + '/ocdskingfisherarchive/' %}

{{ giturl }}{{ ocdskingfisherdir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - branch: master
    - rev: master
    - target: {{ ocdskingfisherdir }}
    - require:
      - pkg: git
      - user: {{ user }}_user_exists

/etc/sudoers.d/archive:
  file.managed:
    - source: salt://ocdskingfisherarchive/archive.sudoers
    - makedirs: True

{{ userdir }}/.pgpass:
  file.managed:
    - source: salt://postgres/ocdskingfisher_archive_.pgpass
    - template: jinja
    - user: {{ user }}
    - group: {{ user }}
    - mode: 0400
    - require:
      - user: {{ user }}_user_exists

{{ userdir }}/logs:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - require:
      - user: {{ user }}_user_exists

/etc/logrotate.d/archive:
  file.managed:
    - source: salt://ocdskingfisherarchive/logrotate
    - makedirs: True

cd {{ ocdskingfisherdir }}; ./rsync-downloaded-files.sh  >> {{ userdir }}/logs/rsync-downloaded-files.log 2>&1:
  cron.present:
    - identifier: OCDS_KINGFISHER_ARCHIVE_RUN
    - user: {{ user }}
    - minute: 0
    - hour: 1
#    - dayweek: 6
