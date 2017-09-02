This directory is a sample directory for running aws-cli.

For example, if you want to download files from S3 in bulk, you can download all the files by entering the following command.
The current directory is attached to /app on Docker. Please specify the directory under /app as the download destination.
```
$ docker-compose run --rm aws-cli aws s3 cp --region ap-northeast-1 s3://dirname/ /app/dirname --recursive
```

To upload files to S3, reverse the directory specification.
```
$ docker-compose run --rm aws-cli aws s3 cp --region ap-northeast-1 /app/dirname s3://dirname/ --recursive
```

