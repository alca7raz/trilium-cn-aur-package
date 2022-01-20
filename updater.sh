#!/bin/bash

raw_version=$(curl https://github.com/Nriver/trilium-translation/releases/latest)
latest_version=$(echo ${raw_version} | awk -F'<html><body>You are being <a href="https://github.com/Nriver/trilium-translation/releases/tag/v' '{print $2}' | awk -F'">redirected</a>.</body></html>' '{print $1}')
last_version=$(cat LATEST)

echo -e "\e[32mLATEST VERSION\e[0m: ${latest_version}" >> message
echo -e "\e[33mLAST VERSION\e[0m\t: ${last_version}" >> message

if [[ ${latest_version} = ${recent_version} ]]; then
    echo -e "\e[34m ==========>\e[0m Package is up-to-date." >> message
    echo -e "\e[34m ==========>\e[0m Nothing to do today." >> message
    exit 1
fi

curl https://github.com/Nriver/trilium-translation/releases/download/v${latest_version}/trilium-cn-linux-x64.zip -L -o trilium-cn-linux-x64.zip
sha256sum=$(sha256sum trilium-cn-linux-x64.zip | awk -F'  ' '{print $1}')

# 编辑templete
sed "s/%%pkgver%%/${latest_version}" PKGBUILD.templete -i
sed "s/%%sha256sum%%/${sha256sum}" PKGBUILD.templete -i

sed "s/%%pkgver%%/${latest_version}" SRCINFO.templete -i
sed "s/%%sha256sum%%/${sha256sum}" SRCINFO.templete -i

echo ${sha256sum} > LATEST

mkdir workdir && cd workdir
git clone https://${GITHUB_TOKEN}@${REPO}
cd trilium-cn-aur-package
cp ../../LATEST ./LATEST
git add LATEST
git commit -m "New Version ${latest_version}"
git push -u origin main

echo ${AUR_PRIVKEY} > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
ssh-keyscan aur.archlinux.org >> ~/.ssh/known_hosts

cd ..
git clone aur@aur.archlinux.org:trilium-bin-cn.git && cd trilium-bin-cn
cp ../../PKGBUILD.templete ./PKGBUILD
cp ../../SRCINFO.templete ./.SRCINFO
git add PKGBUILD .SRCINFO
git commit -m "Update ${latest_version}"
git push -u origin master

cd ../..
echo -e "\e[32m ==========>\e[0m Package has been updated." >> message
