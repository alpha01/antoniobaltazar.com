#/bin/sh

npm install

./node_modules/gulp/bin/gulp.js build

if [ "$APP_ENV" == "dev" ]; then
    ./node_modules/gulp/bin/gulp.js watch
else
    cp -r /vendor/ /vendor-assets/ # Jenkins
fi