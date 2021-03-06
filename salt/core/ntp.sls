# Disable pre-installed systemd-timesyncd as we prefer NTP.
systemd-timesyncd:
  service.dead:
    - enable: False

ntp:
  pkg:
    - installed
  service.running:
    - enable: True
    - watch:
      - file: /etc/ntp.conf

/etc/ntp.conf:
  file.replace:
    - pattern: "ubuntu.pool.ntp.org"
    - repl: "uk.pool.ntp.org"
  require:
    - pkg: ntp

# Set timezone to UTC.
UTC:
  timezone.system
