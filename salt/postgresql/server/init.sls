{% set postgresql = salt["pillar.get"]("postgresql", {}) %}
{% set data_partitions = salt["rackspace.data_partitions"]() %}

{% if "postgresql-replica" in grains["roles"] %}
{% set postgresql_primary = ((salt["mine.get"]("roles:postgresql-primary", "minealiases.psf_internal", expr_form="grain").items())|sort(attribute='0')|first)[1]|sort()|first %}
{% else %}
{% set postgresql_replicas = salt["mine.get"]("roles:postgresql-replica", "minealiases.psf_internal", expr_form="grain") %}
{% endif %}

{% if data_partitions|length() > 1 %}
This Does Not Support Multi Data Disk Servers!!!!
{% endif %}

include:
  - monitoring.client.collectors.postgresql
{% if "postgresql-primary" in grains["roles"] %}
  - .wal-e
{% endif %}

postgresql-data:
{% if data_partitions %}
  blockdev.formatted:
    - name: /dev/{{ data_partitions[0].partition }}
    - fs_type: ext4

  mount.mounted:
    - name: /srv/postgresql
    - device: /dev/{{ data_partitions[0].partition }}
    - fstype: ext4
    - mkmnt: True
    - opts: "data=writeback,noatime,nodiratime"
    - require:
      - blockdev: postgresql-data
{% endif %}

  file.directory:
    - name: /srv/postgresql/9.3
    - user: root
    - group: root
    - mode: 777
{% if data_partitions %}
    - require:
      - mount: postgresql-data
{% else %}
    - makedirs: True
{% endif %}


postgresql-server:
  pkg.installed:
    - pkgs:
      - postgresql-9.3
      - postgresql-contrib-9.3

  cmd.run:
    - name: pg_dropcluster --stop 9.3 main
    - onlyif: pg_lsclusters | grep '^9\.3\s\+main\s\+'
    - require:
      - pkg: postgresql-server

  service.running:
    - name: postgresql
    - enable: True
    - watch:
      - file: {{ postgresql.hba_file }}
      - file: {{ postgresql.config_file }}
      - file: {{ postgresql.ident_file }}
      {% if "postgresql-replica" in grains["roles"] %}
      - file: {{ postgresql.recovery_file }}
      {% endif %}
    - require:
      - cmd: postgresql-psf-cluster
      - file: {{ postgresql.hba_file }}
      - file: {{ postgresql.config_file }}
      - file: {{ postgresql.ident_file }}
      - file: {{ postgresql.config_dir }}/conf.d
      {% if "postgresql-replica" in grains["roles"] %}
      - file: {{ postgresql.recovery_file }}
      {% endif %}


postgresql-psf-cluster:
  cmd.run:
    {% if "postgresql-primary" in grains["roles"] %}
    - name: pg_createcluster --datadir {{ postgresql.data_dir }} --locale en_US.UTF-8 9.3 --port {{ postgresql.port }} psf
    {% elif "postgresql-replica" in grains["roles"] %}
    - name: pg_basebackup --pgdata {{ postgresql.data_dir }} -U replicator
    - env:
      - PGHOST: {{ postgresql_primary }}
      - PGPORT: "{{ postgresql.port }}"
      - PGPASSWORD: {{ pillar["postgresql-users"]["replicator"] }}
    - user: postgres
    {% endif %}
    - unless: pg_lsclusters | grep '^9\.3\s\+psf\s\+'
    - require:
      - pkg: postgresql-server
      - file: postgresql-data


# Make sure that our log directory is writeable
/var/log/postgresql:
  file.directory:
    - user: postgres
    - group: postgres
    - mode: 755

# Make sure that our log file is writeable
/var/log/postgresql/postgresql-9.3-psf.log:
  file.managed:
    - user: postgres
    - group: postgres
    - mode: 640


{{ postgresql.config_dir }}:
  file.directory:
    - user: postgres
    - group: postgres
    - mode: 755
    - makedirs: True
    - require:
      - cmd: postgresql-psf-cluster


{{ postgresql.config_dir }}/conf.d:
  file.directory:
    - user: postgres
    - group: postgres
    - mode: 755
    - makedirs: True
    - require:
      - file: {{ postgresql.config_dir }}


{{ postgresql.hba_file }}:
  file.managed:
    - source: salt://postgresql/server/configs/pg_hba.conf.jinja
    - template: jinja
    - user: postgres
    - group: postgres
    - mode: 640
    - require:
      - cmd: postgresql-psf-cluster
      - file: {{ postgresql.config_dir }}


{{ postgresql.config_file }}:
  file.managed:
    - source: salt://postgresql/server/configs/postgresql.conf.jinja
    - template: jinja
    - user: postgres
    - group: postgres
    - mode: 640
    - require:
      - cmd: postgresql-psf-cluster
      - file: {{ postgresql.config_dir }}


{{ postgresql.ident_file }}:
  file.managed:
    - source: salt://postgresql/server/configs/pg_ident.conf.jinja
    - template: jinja
    - user: postgres
    - group: postgres
    - mode: 640
    - require:
      - cmd: postgresql-psf-cluster
      - file: {{ postgresql.config_dir }}


{% if "postgresql-replica" in grains["roles"] %}
{{ postgresql.recovery_file }}:
  file.managed:
    - source: salt://postgresql/server/configs/recovery.conf.jinja
    - template: jinja
    - user: postgres
    - group: postgres
    - mode: 640
    - require:
      - cmd: postgresql-psf-cluster
      - file: {{ postgresql.config_dir }}
{% endif %}


{% if "postgresql-primary" in grains["roles"] %}

replicator:
  postgres_user.present:
    - replication: True
    - password: {{ pillar["postgresql-replicator"] }}
    - require:
      - service: postgresql-server

{% for user, password in salt["pillar.get"]("postgresql-superusers", {}).items() %}
{{ user }}-superuser:
  postgres_user.present:
    - name: {{ user }}
    - superuser: True
    - password: {{ password }}
    - require:
      - service: postgresql-server
{% endfor %}

{% for user, password in salt["pillar.get"]("postgresql-users", {}).items() %}
{{ user }}-user:
  postgres_user.present:
    - name: {{ user }}
    - password: {{ password }}
    - require:
      - service: postgresql-server
{% endfor %}

{% for database, user in postgresql.get("databases", {}).items() %}
{{ database }}-database:
  postgres_database.present:
    - name: {{ database }}
    - owner: {{ user }}
    - require:
      - service: postgresql-server
      - postgres_user: {{ user }}-user
{% endfor %}

{% endif %}
