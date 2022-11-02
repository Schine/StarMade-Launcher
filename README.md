# StarMade Launcher
Written in node, this graphical fanciness allows the user to easily update/select their installed build of StarMade and its launch options.

To install, run these in the launcher directory:
  1) `npm install`*
  2) `npm install -g bower`*
  3) `bower install`*
  4) `npm install -g gulp`*
  5) (see fixes below)
  6) `gulp bootstrap`

(*On ubuntu you may need to run these commands with `sudo`)


And to run the launcher afterward, simply run: `gulp`



------

### Fixes
There are currently three out-of-box issues with the launcher.  Here are the steps to remedy them:

#### buildHash.js
create a blank file here:  build/lib/buildHash.js

#### License error for json-schema:
copy the contents of https://raw.githubusercontent.com/dojo/dojox/master/LICENSE to `launcher/node_modules/request/node_modules/http-signature/node_modules/jsprim/node_modules/json-schema/LICENSE`

#### Missing Java dependencies for win32/64:
Download the Java jre archive(s) from here:
  * win32: https://s3.amazonaws.com/sm-launcher/java/jre-7u80-windows-i586.tar.gz
  * win64: https://s3.amazonaws.com/sm-launcher/java/jre-7u80-windows-x64.tar.gz

and manually extract the contents to `dep/java/(platform)`, e.g. `dep/java/win64`

## Copyright / License

Copyright (c) Schine GmbH.

All **source code** is made available under the [MIT license](LICENSE.txt).

For further information on licenses and copyright please see [NOTICE.txt](NOTICE.txt).