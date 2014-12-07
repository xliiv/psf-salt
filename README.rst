Python Infrastructure
=====================

* `Documentation <http://infra.psf.io/>`_
* `IRC: #python-infra on Freenode <http://webchat.freenode.net?channels=%23python-infra>`_


Development:
------------

Forge:
    From psf-salt dir do::

        $ vagrant up salt-master
        $ vagrant up forge
        $ vagrant ssh forge
        vagrant@forge:~$ w3m http://127.0.0.1:80
