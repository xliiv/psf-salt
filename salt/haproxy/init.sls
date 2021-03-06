include:
  - monitoring.client.collectors.haproxy


haproxy:
  pkgrepo.managed:
    - ppa: vbernat/haproxy-1.5
    - keyid: CFFB779AADC995E4F350A060505D97A41C61B9CD
    - require_in:
      - pkg: haproxy

  pkg:
    - installed

  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/haproxy/haproxy.cfg
    - require:
      - pkg: haproxy
      - file: /etc/haproxy/haproxy.cfg


/etc/haproxy/haproxy.cfg:
  file.managed:
    - source: salt://haproxy/config/haproxy.cfg.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: haproxy
      - file: /etc/ssl/private/*.pem


/etc/ssl/private/ev.python.org.pem:
  file.managed:
    - contents_pillar: tls_certs:ev.python.org
    - user: root
    - group: root
    - mode: 600


/etc/ssl/private/hg.python.org.pem:
  file.managed:
    - contents_pillar: tls_certs:hg.python.org
    - user: root
    - group: root
    - mode: 600

/etc/ssl/private/star.python.org.pem:
  file.managed:
    - contents_pillar: tls_certs:star.python.org
    - user: root
    - group: root
    - mode: 600
