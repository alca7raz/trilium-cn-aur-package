#!/bin/bash

rm -f message

latest_version=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/Nriver/trilium-translation/releases |\
    grep "tag_name" | awk -F': ' '{print $2}' | sed 's/[",v]//g' | sed -n '1p')
[[ $? != 0 ]] && echo -e "\e[31mERROR\e[0m: Get version failed. Curl quit unexpected." >> message && exit 2
[[ -z ${latest_version} ]] && echo -e "\e[31mERROR\e[0m: Get version failed. Curl result is empty." >> message && exit 3

last_version=$(cat LATEST)

echo -e "\e[32mLATEST VERSION\e[0m: ${latest_version}" >> message
echo -e "\e[33mLAST VERSION\e[0m: ${last_version}" >> message

if [[ ${latest_version} = ${last_version} ]]; then
    echo -e "\e[34m ==========>\e[0m Package is up-to-date." >> message
    echo -e "\e[34m ==========>\e[0m Nothing to do today." >> message
    exit
fi

# 生成SHA256SUM
curl https://github.com/Nriver/trilium-translation/releases/download/v${latest_version}/trilium-cn-linux-x64.zip -LOC -
sha256sum=$(sha256sum trilium-cn-linux-x64.zip | awk -F'  ' '{print $1}')

# 更新缓存版本号
mkdir workdir && cd workdir
git clone https://${REPO} && cd trilium-cn-aur-package
echo ${latest_version} > LATEST
git add LATEST
git config user.name ${GH_NAME}
git config user.email ${GH_EMAIL}
git commit -m "New Version ${latest_version}"
git push "https://${GITHUB_TOKEN}@${REPO}" main:main
cd ../..

# 编辑templete
sed "s/%%pkgver%%/${latest_version}/g" PKGBUILD.templete -i
sed "s/%%sha256sum%%/${sha256sum}/g" PKGBUILD.templete -i

sed "s/%%pkgver%%/${latest_version}/g" SRCINFO.templete -i
sed "s/%%sha256sum%%/${sha256sum}/g" SRCINFO.templete -i

# 更新AUR
cd workdir
git clone aur@aur.archlinux.org:trilium-bin-cn.git && cd trilium-bin-cn
cp -f ../../PKGBUILD.templete ./PKGBUILD
cp -f ../../SRCINFO.templete ./.SRCINFO
git add PKGBUILD .SRCINFO
git config user.name ${AUR_NAME}
git config user.email ${AUR_EMAIL}
git commit -m "Update ${latest_version}"
git push -u origin master

cd ../..
echo -e "\e[32m ==========>\e[0m Package has been updated." >> message
rm -rf workdir

