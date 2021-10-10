# set up the alias
mc alias set minio http://localhost:9000  ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}

# add user log-downloader
mc admin user add minio log-download ${LOG_DOWNLOAD_KEY}

# add user loguploader
mc admin user add minio log-upload ${LOG_UPLOAD_KEY}

# add user repoitoryCacher
mc admin user add minio repository-cache ${REPOSITORY_CACHE_KEY}

# create buckets 'logs' and 'repositories'
mc mb minio/repositories -p
mc mb minio/logs -p

# create policies
echo '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:PutObject*"],"Resource":["arn:aws:s3:::logs/*"]}]}' > log-upload.json
mc admin policy add minio log-upload log-upload.json
echo '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject*","s3:ListBucket"],"Resource":["arn:aws:s3:::logs/*"]}]}' > log-download.json
mc admin policy add minio log-download log-download.json
echo '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:DeleteObject*", "s3:PutObject*", "s3:GetObject*","s3:ListBucket"],"Resource":["arn:aws:s3:::repositories/*"]}]}' > repository-cache.json
mc admin policy add minio repository-cache repository-cache.json

rm log-upload.json log-download.json repository-cache.json

# create bucket policies
echo '{"Rules":[{"Expiration":{"Days": 14,"DeleteMarker": false},"ID": "c5d1b540hsj8t52p6e2g","Status": "Enabled"}]}' | mc ilm import minio/logs
echo '{"Rules":[{"Expiration":{"Days": 31,"DeleteMarker": false},"ID": "c5d1b540hsj8t52p6e2h","Status": "Enabled"}]}' | mc ilm import minio/repositories

# attach policies to user
mc admin policy set minio log-download user=log-download
mc admin policy set minio log-upload user=log-upload
mc admin policy set minio repository-cache user=repository-cache