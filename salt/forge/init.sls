# TODO:
# add rule to firewall
# update static_files path in wsgi.py
# change vagrant user to e.g. kallithea
# configure postgres db
# rm hardcodes from init-db command
# finish handling celery (inc: password, which is now kallitheapass)
# add doc

include:
  - nginx
  - postgresql.client

kallithea:
  pkg.installed:
    - pkgs:
      - gunicorn
      - python-dev
      - python-pip
      - python-virtualenv
      - rabbitmq-server

  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /kallithea/data/wsgi.py
      - file: /etc/init/kallithea.conf
    - require:
      - pkg: kallithea
      - file: /var/log/kallithea
      - file: /var/run/gunicorn
      - cmd: kallithea-init-db

/kallithea:
  file.directory:
    - user: vagrant
    - group: vagrant
    - mode: 750
/kallithea/repos:
  file.directory:
    - user: vagrant
    - group: vagrant
    - mode: 750
    - require:
      - file: /kallithea
/kallithea/data:
  file.directory:
    - user: vagrant
    - group: vagrant
    - mode: 750
    - require:
      - file: /kallithea

/kallithea/venv:
    virtualenv.managed:
        - no_site_packages: True
        - runas: vagrant
        - requirements: salt://forge/configs/requirements.txt
        - require:
            - file: /kallithea
            - pkg: kallithea

kallitheauser:
    rabbitmq_user.present:
# TODO: need password
        - password: kallitheapass
        - force: True

kallitheavhost:
    rabbitmq_vhost.present:
        - user: kallitheauser
        - conf: .*
        - write: .*
        - read: .*

# kallithea initialization db, etc.
/kallithea/data/production.ini:
    file.managed:
        - source: salt://forge/configs/production.ini
        - user: vagrant
        - group: vagrant
        - mode: 750
        - require:
          - file: /kallithea/data

kallithea-init-db:
  cmd.run:
    - name: ". /kallithea/venv/bin/activate && paster setup-db production.ini --user=admin1 --email=tymoteusz.jankowski@gmail.com --password=admin1 --repos=/kallithea/repos --force-yes"
    - cwd: /kallithea/data/
    - require:
        - pkg: kallithea
        - virtualenv: /kallithea/venv
        - file: /kallithea/repos
        - file: /kallithea/data/production.ini

# kallithea as a upstart service
/etc/kallithea:
  file.directory:
    - group: vagrant
    - mode: 750
    - require:
      - pkg: kallithea

/etc/init/kallithea.conf:
  file.managed:
    - source: salt://forge/configs/kallithea-init.conf
    - user: root
    - group: root
    - mode: 644

# kallithea by gunicorn
/kallithea/data/wsgi.py:
    file.managed:
        - source: salt://forge/configs/wsgi.py
        - require:
          - file: /kallithea/data

/var/run/gunicorn:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 777
    - file_mode: 666
    - require:
      - pkg: kallithea
      - file: /kallithea/data/wsgi.py

# nginx stuff
/etc/nginx/sites.d/kallithea.conf:
  file.managed:
    - source: salt://forge/configs/kallithea-nginx.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - sls: nginx

/var/log/kallithea:
  file.directory:
    - user: root
    - group: vagrant
    - dir_mode: 775
    - file_mode: 664
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: kallithea
