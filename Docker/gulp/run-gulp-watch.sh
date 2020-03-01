#/bin/sh

npm install

./node_modules/gulp/bin/gulp.js build

if [ "$APP_ENV" = "dev" ]; then
    ./node_modules/gulp/bin/gulp.js watch
else
    rm -rvf /vendor-assets/*
    cp -rv /vendor/ /vendor-assets/
    # weird shared volume copy issue
    mv /vendor-assets/vendor/* /vendor-assets/ && rmdir /vendor-assets/vendor/

fi
