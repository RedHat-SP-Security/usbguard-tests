#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /usbguard/Sanity/notifier-ipc
#   Author: Dalibor Pospisil <dapospis@redhat.com>
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

rlJournalStart && {
  rlPhaseStartSetup && {
    rlRun "rlImport --all" 0 "Import libraries" || rlDie "cannot continue"
    rlRun "rlCheckMakefileRequires" || rlDie "cannot continue"
    rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
    CleanupRegister "rlRun 'rm -r $TmpDir' 0 'Removing tmp directory'"
    CleanupRegister 'rlRun "popd"'
    rlRun "pushd $TmpDir"
    CleanupRegister 'rlRun "rlFileRestore"'
    rlRun "rlFileBackup --clean /etc/usbguard"
    CleanupRegister 'rlRun "rlServiceRestore usbguard"'
    rlRun "rlServiceStart usbguard"
    CleanupRegister 'rlRun "testUserCleanup"'
    rlRun "testUserSetup"
    #systemd-logind could be broken by dbus test, provide restart of service
    rlRun "systemctl restart systemd-logind"
    sleep 2
  rlPhaseEnd; }

  rlPhaseStartTest "global service setting" && {
    rlRun "systemctl status --user usbguard-notifier" 1-255
    rlRun "systemctl is-active --user usbguard-notifier" 1-255
  rlPhaseEnd; }

sshRun() {
  rlRun "loginctl terminate-user $testUser" 0-255
  rlRun -s "expect" 0 "ssh $testUser@127.0.0.1 \"$1\"" << EOE
    spawn ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $testUser@127.0.0.1 "$1"
    expect assword { send "$testUserPasswd\r" }
    expect eof
EOE
}

userServiceCheck() {
  sshRun "sleep 5; systemctl status --user usbguard-notifier; sleep 1"
}

  rlPhaseStartTest "user service setting" && {
    rlLog "service disabled"
    # Sleep some more because notifier will retrieve a few times before failing
    rlRun "sleep 10"
    userServiceCheck
    # notifier will exit, thus not be active
    rlRun "systemctl is-active --user usbguard-notifier" 1-255
    rlRun -s "rlServiceStatus usbguard"
    rlAssertNotGrep "IPC connection denied" $rlRun_LOG
    rm -f $rlRun_LOG

    rlLog "service enabled but IPC not allowed"
    sshRun "sleep 1; systemctl enable --user usbguard-notifier; sleep 1"
    # Sleep some more because notifier will retrieve a few times before failing
    rlRun "sleep 10"
    userServiceCheck
    # notifier will exit, thus not be active
    rlRun "systemctl is-active --user usbguard-notifier" 1-255
    rm -f $rlRun_LOG
    rlRun -s "rlServiceStatus usbguard"
    rlAssertGrep "IPC connection denied" $rlRun_LOG
    rm -f $rlRun_LOG

    rlLog "service enabled and IPC granted"
    rlRun "usbguard add-user $testUser -d listen"
    rlRun "rlServiceStart usbguard"
    rlRun "systemctl restart --user usbguard-notifier"
    sshRun "sleep 1; systemctl status --user usbguard-notifier; sleep 1"
    userServiceCheck
    # When service is enabled and IPC granted, notifier will be active
    rlRun "systemctl is-active --user usbguard-notifier" 0
    # rlAssertGrep 'running' $rlRun_LOG
    rm -f $rlRun_LOG
    rlRun -s "rlServiceStatus usbguard"
    rlAssertNotGrep "IPC connection denied" $rlRun_LOG
    rlAssertGrep "running" $rlRun_LOG -iq
    rm -f $rlRun_LOG
  rlPhaseEnd; }

  rlPhaseStartCleanup && {
    CleanupDo
    #usbguard notifial need to stopped
    rlRun "systemctl stop --user usbguard-notifier"
  rlPhaseEnd; }
  rlJournalPrintText
rlJournalEnd; }
