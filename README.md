![Docker pulls](https://img.shields.io/docker/pulls/atareao/mariadb-backup)

# volume-backup

Volume Backup to the local filesystem with monthly rotating backups. Only one volume can be backup, but many folders in this volume.

Supports the following Docker architectures: `linux/amd64`, `linux/arm64`.

Please consider reading detailed the [How the backups folder works?](#how-the-backups-folder-works).

## Usage


Docker Compose:

```yaml
services:
  backup:
    image: atareao/volume-backup
    container_name: backup
    restart: always
    init: true
    environment:
      SCHEDULE: "0 3 * * *"
      BACKUP_DIR: "/backup"
      VOLUME: "sample1"
      MOUNTED_FOLDER: "/tmp/folder1"
      KEEP_MONTHS: 3
    volumes:
      - backup:/backup:rw
      - sample1:/tmp/folder1:ro

volumes:
  backup: {}
  sample1: {}

```

### Environment Variables

| env variable | description |
|--|--|
| SCHEDULE | [tokio-cron-scheduler](https://docs.rs/crate/tokio-cron-scheduler/latest) specifying the interval between postgres backups. Defaults to `0 0 */24 * * * *`. |
| BACKUP_DIR | Directory to save the backup at. Defaults to `/backup`. |
| VOLUME | Volume to be backuped|
| MOUNTED_FOLDER | Folder to be mounted|
| KEEP_MONTHS | Number of monthly backups to keep before removal. Defaults to `6`. |


### How the backups folder works?

Every day that is scheduled a backup is done. If it is the first day of month, the backup is full, but is another day the backup is incremetal relative to first day of month. It means that second day is incremental relative to first, third day relative to second, and so on.

So, to recover one day you must restore first day and the day you want to restore.

So the backup folder are structured as follows:

* `BACKUP_DIR/monthly/VOLUME-YYYYMM/YYYYMMDD.tar.gz`: For every volume and month there is a folder where every backup is stored.
* `BACKUP_DIR/monthly/VOLUME-YYYYMM/YYYYMMDD.snap`: Besides the data.


For **cleaning** the script removes the months that not want to store.

### Hooks

The folder `hooks` inside the container can contain hooks/scripts to be run in differrent cases getting the exact situation as a first argument (`error`, `pre-backup` or `post-backup`).

Just create an script in that folder with execution permission so that [run-parts](https://manpages.debian.org/stable/debianutils/run-parts.8.en.html) can execute it on each state change.

Please, as an example take a look in the script already present there that implements the `WEBHOOK_URL` functionality.

### Manual Backups

By default this container makes daily backups, but you can start a manual backup by running `/backup.sh`.

This script as example creates one backup as the running user and saves it the working folder.
