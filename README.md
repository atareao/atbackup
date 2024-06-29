![Docker pulls](https://img.shields.io/docker/pulls/atareao/atbackup)

# atbackup

atabakcup makes dump of MariaDB databases and folders of directories using borgbackup.

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
    volumes:
      - ./config.json:/config.json
      - ./config_ssh.txt:/config_ssh.txt
      - ./id_backupuser:/root/.ssh/id_backupuser
      - atbackup:/backup
      - local_backup:/tmp/local_backup

volumes:
  atbackup: {}
  local_backup:
    external: true
```

* `atbackup` volume stores the sql database
* `local_backup` volume stores a local backup.

### Environment Variables

| env variable | description |
|--|--|
| SCHEDULE | [Cron Syntax in the Job Scheduler](https://en.wikipedia.org/wiki/Cron) specifying the interval between postgres backups. Defaults to `0 0 */24 * * * *`. |

### config.json

This files is the configuration you need to backup. For example,

* `repositories` the configuration for all repositories where you want to save the backup.
* `include` are the directories that you want to make a backup
* `exclude` are folders you want to exclude
* `mariadb` are MariaDB servers. This servers must be in the same netrwork
* `prune`, it's the configuration to clean older backup using retention policies, as `whitin`, `weekly` and `monthly`

```json
{
    "repositories": [
        {
            "bin": "/usr/bin/borg",
            "path": "host:/home/backupser/test",
            "pass": "12345678"
        },
        {
            "bin": "/usr/bin/borg",
            "path": "/tmp/local_backup",
            "pass": "12345678"
        }
    ],
    "include": [
        "/backup",
        "/html/wp-content"
    ],
    "exclude": [
        "*.aup",
        "*.mp3",
        "/data/rust/*/target"
    ],
    "mariadb": [
        {
            "host": "mariadb",
            "port": "3306",
            "password": "mypass"
        }
    ],
    "prune": {
        "within": "5d",
        "weekly": "2",
        "monthly": "2"
    }
}
```

### Configure remote directories

To configure remote directories you must run this command,

```bash
borg init --encryption repokey <directory>
```

In the previous sample 




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
