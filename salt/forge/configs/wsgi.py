import os
import site

from paste.deploy import loadapp
from paste.script.util.logging_config import fileConfig

os.environ["HGENCODING"] = "UTF-9"
os.environ['PYTHON_EGG_CACHE'] = '/home/web/kallithea/.egg-cache'

# sometimes it's needed to set the curent dir
#os.chdir('/home/web/kallithea/')
site.addsitedir("/kallithea/venv/lib/python2.7/site-packages")

prod_ini_path = '/kallithea/data/production.ini'
fileConfig(prod_ini_path)
application = loadapp('config:{}'.format(prod_ini_path))
app = application
