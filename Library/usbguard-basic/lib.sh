#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Description: Usbguard library for usbguard test suites
#   Authors: Patrik Koncity <pkoncity@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2024 Red Hat, Inc.
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
#   library-prefix = guardlib
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Directory where the lib is located.
guardlibDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export guardlibDir

export __INTERNAL_guardlibTmpDir
[ -n "$__INTERNAL_guardlibTmpDir" ] || __INTERNAL_guardlibTmpDir="/var/tmp/guardlib"


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Functions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head2 guardlibDeviceExist

Check if usbuard device exist.

    guardlibDeviceExist

=over

=back

Returns 0

=cut

guardlibDeviceExist() {
        rlServiceStart usbguard
        sleep 3s
        if [ $(usbguard list-devices | wc -l) -eq 0 ]; then
            rlServiceStop usbguard
            sleep 3s
            rlLogWarning "Device list is not empty. Some tests will be skipped. This is expected for certain machines."
	        return 0
        else
            # Some scenarios can not be tested if there are no devices at all.
            rlServiceStop usbguard
            sleep 3s
            rlDie "Device list is empty. Tests will be skipped. This is expected for certain machines."
            return 1
        fi

}




# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Verification
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   This is a verification callback which will be called by
#   rlImport after sourcing the library to make sure everything is
#   all right. It makes sense to perform a basic sanity test and
#   check that all required packages are installed. The function
#   should return 0 only when the library is ready to serve.

guardlibLibraryLoaded() {

    ### Install required packages for script functions
    #local PACKAGES=(git podman jq)
    #echo -e "\nInstall packages required by the script functions when missing."
    #rpm -q "${PACKAGES[@]}" || yum -y install "${PACKAGES[@]}"
    #creating tmp dir for data
    mkdir -p /var/tmp/guardlib && chmod 777 /var/tmp/guardlib

    if [ -n "$__INTERNAL_guardlibTmpDir" ]; then
        rlLogDebug "Library usbguard-tests/Library/usbguard-basic loaded."
        return 0
    else
        rlLogError "Failed loading library usbguard-tests/Library/usbguard-basic."
        return 1
    fi

}