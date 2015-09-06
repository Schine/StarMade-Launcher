'use strict'

app = angular.module 'launcher-self-updater', []

# Controllers
require('./controllers/selfUpdater')

# Services
require('./services/Checksum')
require('./services/Version')
require('./services/updater')
require('./services/updaterProgress')
