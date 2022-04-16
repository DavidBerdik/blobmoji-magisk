rm -vf Blobmoji-latest.zip
zip -r Blobmoji-latest.zip . -x ".git/*" ".gitattributes" "build-module.sh" "noto.png" "README.md"
