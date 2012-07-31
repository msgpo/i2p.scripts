#!/bin/bash

###
### Export from monotone to git
###
### Monotone doesn't handle suspend certs correctly when doing
### a git_export, so they must be killed locally before exporting.
###
### By duck and zzz May 2011
###

cd $(dirname "$0")

MTN=mtn
MTN_VERSION=`$MTN --version | cut -d' ' -f2`

echo "Pulling latest from mtn"
# Try up to 10 times
COUNT=0
while [ $COUNT -lt 10 ]; do
  $MTN --db i2p.mtn pull 127.0.0.1:8998 i2p.i2p --key=
  if [ $? -eq 0 ]; then
    break
  fi
  let "COUNT+=1"
done
if [ $COUNT -ge 10 ]; then
  echo Can\'t pull from mtn, aborting.
  exit 1
fi
echo

echo "Killing bad revs"
if [[ $MTN_VERSION == 1* ]]; then
  # mtn 1.0 syntax
  $MTN --db i2p.mtn local kill_rev 18c652e0722c4e4408b28036306e5fb600f63472
  $MTN --db i2p.mtn local kill_rev 7d2f18d277a34eb2772fa9380449c7fdb4dcafcf
else
  # mtn 0.48 syntax
  $MTN --db i2p.mtn db kill_rev_locally 18c652e0722c4e4408b28036306e5fb600f63472
  $MTN --db i2p.mtn db kill_rev_locally 7d2f18d277a34eb2772fa9380449c7fdb4dcafcf
fi
echo

if [[ $MTN_VERSION == 1* ]]; then
  # mtn 1.0 syntax
  HEADS=`$MTN --db i2p.mtn head --no-standard-rcfiles --ignore-suspend-certs -b i2p.i2p 2> /dev/null | wc -l`
else
  # mtn 0.48 syntax
  HEADS=`$MTN --db i2p.mtn head --ignore-suspend-certs -b i2p.i2p 2> /dev/null | wc -l`
fi
if [ $HEADS -gt 1 ]; then
  echo "Heads:"
  $MTN --db i2p.mtn head --ignore-suspend-certs -b i2p.i2p
  echo Multiple heads, aborting!
  exit
fi

echo "Exporting to git format"
$MTN --db i2p.mtn git_export > i2p.git_export
echo

cd i2p.git
echo "Importing into git"
git fast-import < ../i2p.git_export

echo "Pushing to github"
git checkout i2p.i2p
git push origin i2p.i2p

cd ..

