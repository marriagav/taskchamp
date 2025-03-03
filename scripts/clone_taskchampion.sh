set -e

cd ..
git clone --no-checkout --depth=1 --filter=blob:none https://github.com/GothenburgBitFactory/taskwarrior
cd taskwarrior
git config core.sparseCheckout true
echo "src/taskchampion-cpp" >> .git/info/sparse-checkout

git checkout

