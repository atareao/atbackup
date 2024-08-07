#!/usr/bin/env sh
# -*- coding: utf-8 -*-

# Copyright (c) 2023 Lorenzo Carbonell <a.k.a. atareao>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Exit if any command fails
set -o errexit
set -o nounset

echo "=== Create ssh confi ==="
cp /config_ssh.txt ~/.ssh/config
chmod 600 ~/.ssh/config

echo "=== Generate crontab.txt ==="
echo "$HOME"
SCHEDULE="${SCHEDULE:-0 2 * * *}"
echo "${SCHEDULE} /bin/sh /backup.sh >> /proc/1/fd/1" > /cronitab/root

LOGLEVEL=${LOGLEVEL:-debug}
echo "Set log level to '${LOGLEVEL}'"
echo "Starting crond... $(date)"
crond -c /cronitab -f -l "${LOGLEVEL}"

