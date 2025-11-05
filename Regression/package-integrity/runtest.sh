#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/usbguard/Regression/package-integrity
#   Author: Natália Bubáková <nbubakov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
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
. /usr/bin/rhts-environment.sh || :
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="usbguard"

rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport --all" 0 "Import libraries" || rlDie "cannot continue"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        CleanupRegister "rlRun 'rm -r $TmpDir' 0 'Removing tmp directory'"
        CleanupRegister 'rlRun "popd"'
        rlRun "pushd $TmpDir"
        CleanupRegister 'rlRun "rlFileRestore"'
        rlRun "rlFileBackup --clean /etc/usbguard"
        rlRun "dnf -y remove $PACKAGE" 0
    rlPhaseEnd

    rlPhaseStartTest "RHEL-113206 - error during installation"
        rlRun -s "dnf -y install $PACKAGE" 0 "Install usbguard package"
        rlAssertNotGrep "Error .* in rpm package .*" $rlRun_LOG -E
    rlPhaseEnd

    rlPhaseStartTest "RHEL-92260 - mismatch in permissions"
        rlRun -s "ls -ld /var/log/usbguard/"
        rlAssertGrep "drwxr-xr-x.\s+2\s+root\s+root.*/var/log/usbguard/" $rlRun_LOG -E

        rlAssertGrep "d\s+/var/log/usbguard\s+0755\s+root\s+root\s+-\s+-" "/usr/lib/tmpfiles.d/usbguard.conf" -E

        rlRun -s "rpm -qlv usbguard | grep /var/log/usbguard"
        rlAssertGrep "drwxr-xr-x\s+2\s+root\s+root.*/var/log/usbguard" $rlRun_LOG -E

        rlRun -s "rpm -V usbguard"
        rlAssertNotGrep "\.M\.{7}\s+\/var\/log\/usbguard" $rlRun_LOG -E
    rlPhaseEnd

    rlPhaseStartCleanup
        CleanupDo
    rlPhaseEnd

    rlJournalPrintText
rlJournalEnd
