include:
  - nginx
  - nginx.fastly-backend

# Various packages required for building documentation.
doc-pkgs:
  pkg.installed:
    - pkgs:
      - build-essential
      - git
      - mercurial
      - python-dev
      - python-virtualenv
      - texlive
      - texlive-latex-extra
      - texlive-latex-recommended
      - texlive-fonts-recommended
      - zip

docsbuild:
  user.present:
    - createhome: False
    - groups:
      - docs
    - require:
      - group: docs

/srv/docsbuild/:
  file.directory:
    - user: docsbuild
    - group: docsbuild
    - mode: 755
    - require:
      - user: docsbuild

docsbuild-scripts:
   git.latest:
     - name: https://github.com/python/docsbuild-scripts.git
     - target: /srv/docsbuild/scripts/
     - user: docsbuild
     - require:
       - user: docsbuild
       - file: /srv/docsbuild/
       - pkg: doc-pkgs

/srv/docsbuild/environment/:
  virtualenv.managed:
    - user: docsbuild
    - no_deps: True
    - requirements: /srv/docsbuild/scripts/requirements.txt
    - require:
      - git: docsbuild-scripts
      # Theses are needed to build C extensions.
      - pkg: doc-pkgs

docsbuild-full:
  cron.present:
    - identifier: docsbuild-full
    - name: python3 /srv/docsbuild/scripts/build_docs.py
    - user: docsbuild
    - minute: 7
    - hour: 0
    - require:
      - virtualenv: /srv/docsbuild/environment/

docsbuild-quick:
  cron.present:
    - identifier: docsbuild-quick
    - name: python3 /srv/docsbuild/scripts/build_docs.py -q
    - user: docsbuild
    - minute: 7
    - hour: 2-23/3
    - require:
      - virtualenv: /srv/docsbuild/environment/

/var/log/docsbuild/:
  file.directory:
    - user: docsbuild
    - group: docsbuild
    - mode: 755

/etc/logrotate.d/docsbuild:
  file.managed:
    - source: salt://docs/config/docsbuild.logrotate
    - user: root
    - group: root
    - mode: 644

/etc/nginx/sites.d/docs-backend.conf:
  file.managed:
    - source: salt://docs/config/nginx.docs-backend.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/nginx/sites.d/
      - module: self-signed-cert
