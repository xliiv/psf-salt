Python Infrastructure
=====================

* `Documentation <http://infra.psf.io/>`_
* `IRC: #python-infra on Freenode <http://webchat.freenode.net?channels=%23python-infra>`_


Development:
------------

Forge:
^^^^^^

From psf-salt dir do::

    $ vagrant up salt-master
    $ vagrant up kallithea-demo
    $ vagrant ssh kallithea-demo
    vagrant@kallithea-demo:~$ w3m http://127.0.0.1:80

Now you can sign in as a test admin user:
    * User: admin1
    * password: admin1

