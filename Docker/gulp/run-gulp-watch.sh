#/bin/sh

cd /build

npm install

./node_modules/gulp/bin/gulp.js build

# weird shared volume copy issue
# find /vendor-assets/* ! -name '.keep' -exec rm -rf +
rm -rf /vendor-assets/*
cp -r vendor/ /vendor-assets/
mv /vendor-assets/vendor/* /vendor-assets/ && rmdir /vendor-assets/vendor/

if [ "$APP_ENV" = "dev" ]; then
    ./node_modules/gulp/bin/gulp.js watch
fi
