# Direct Web API ダイレクトWebAPIについて
Celebrity Video &amp; LIVE named Direct Web API

PAYJP
https://pay.jp/d/charges

CLOUD RUN
https://console.cloud.google.com/run/detail/asia-northeast1/direct/metrics?project=estplante

BUILD
https://console.cloud.google.com/cloud-build/dashboard?project=direct-video

https://console.cloud.google.com/cloud-build/builds?project=estplante

CLOUD LOGGER
https://console.cloud.google.com/logs/viewer?project=estplante

CLOUD STORAGE
https://console.cloud.google.com/storage/browser/estplante.appspot.com;tab=objects?project=estplante&prefix=&forceOnObjectsSortingFiltering=false

IAM
https://console.cloud.google.com/iam-admin/serviceaccounts/details/106297553981395440464;edit=true?hl=ja&orgonly=true&project=direct-video&supportedpurview=organizationId

FIREBASE
https://console.firebase.google.com/project/direct-video/firestore/data~2FOrder~2F1Ira8LQEBAEAzrAhbHL5

## Local at first time
nodejs 10
npm

## Local at first time
```
npm install
```

## Local server run
```
npm start
```

## Kill a port occupation
```
kill -9 `lsof -i -P | grep 3000 | awk '{print $2}'`
```
## Docker start
```
docker-compose up -d
```
## Docker exec
```
docker-compose exec video /bin/bash
```
## Docker close
```
docker-compose down
```
## Curl to app in local Docker
```
curl -o converted.mp4 -F 'file=@Test.mp4' -F filename=Test.mp4 -u user:pass -X POST http://localhost:3001/video/converter
```
curl -o converted.mp4 -F 'file=@Test.mp4' -F filename=Test.mp4 -u user:pass -X POST https://direct-e225xweoqq-an.a.run.app/video/converter

curl -o converted.mp4 -F 'file=@Test.mp4' -F filename=Test.mp4 -u user:pass -X POST http://localhost:3001/video/converter

curl -o converted2.mp4 -u userid:ef24a29a1e7a055d6af40f48fd8a4e08 -X GET http://localhost:3000/video/get


curl -F 'file=@Test.mp4' -F filename=Test.mp4 -u user:pass -X POST http://localhost:3000/video/upload

curl -u user:pass -X POST http://localhost:3000/video/upload

## Resource
https://console.cloud.google.com/run/detail/asia-northeast1/direct/revisions?hl=ja&project=estplante


TODO プロジェクトがestplanteになっているのをどうにかしないといけない