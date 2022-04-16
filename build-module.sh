rm -vf Blobmoji-latest.zip
zip -r Blobmoji-latest.zip . -x ".git/*" ".gitattributes" ".gitignore" "build-module.sh" "noto.png" "README.md"
