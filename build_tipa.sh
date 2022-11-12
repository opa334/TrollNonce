set -e
make FINALPACKAGE=1

if [ -d ".theos/Payload" ]
then
    rm -rf .theos/Payload
fi

if [ -f "packages/TrollNonce.tipa" ]
then
    rm -rf packages/TrollNonce.tipa
fi

mkdir .theos/Payload
mv .theos/obj/TrollNonce.app .theos/Payload/TrollNonce.app
cp .theos/obj/noncehelper .theos/Payload/TrollNonce.app/noncehelper

mkdir -p packages
cd .theos
zip -vr ../packages/TrollNonce.tipa Payload
cd -

rm -rf .theos/Payload