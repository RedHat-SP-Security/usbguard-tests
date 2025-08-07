#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Natália Bubáková <nbubakov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2025 Red Hat, Inc.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

TESTDIR=`pwd`

function checkFile() {
    MUSTEXIST=false
    if [ "$1" == "-e" ]; then
        MUSTEXIST=true
        shift
    fi
    FILEPATH=$1
    OWNER=$2
    GROUP=$3
    if "$MUSTEXIST" || [ -e "$FILEPATH" ]; then
        ls -ld $FILEPATH
        rlRun "ls -ld $FILEPATH | grep -qE '$OWNER[ ]*$GROUP'"
    fi
}

rlJournalStart

    rlPhaseStartTest "Static file ownership check"
        rlAssertRpm "usbguard"

        # check /etc files
        checkFile -e /etc/usbguard root root
        checkFile -e /etc/usbguard/usbguard-daemon.conf root root
        checkFile -e /etc/usbguard/rules.conf root root
        checkFile -e /etc/usbguard/rules.d/ root root
        checkFile -e /etc/usbguard/IPCAccessControl.d root root

        # check /var files
        checkFile -e /var/log/usbguard root root

        # check /usr files
        checkFile -e /usr/lib/systemd/system/usbguard.service root root
        checkFile -e /usr/bin/usbguard root root
    rlPhaseEnd

    rlPhaseStartTest "Dynamic file ownership check"
        rlServiceStart "usbguard"
        rlRun "systemctl status usbguard" 0 "Confirm that usbguard service is running"

        # check /var files
        checkFile -e /var/log/usbguard/usbguard-audit.log root root
        checkFile -e /var/run/usbguard.pid root root
        
        rlServiceStop "usbguard"
    rlPhaseEnd

rlJournalPrintText
rlJournalEnd