#!/bin/bash

# BU -- USB Backup Tool (Version 1.0) -- by Joe Collins. (www.ezeelinux.com)
# A simple tool to create reliable backups of /etc/ and /home from multiple
# Debian/Ubuntu Linux systems. (May 10, 2019)
# (GNU/General Public License version 2.0)
#
# For Debian 9 and up, Ubuntu 16.04 and up and Linux Mint 18.x and up.
#
# ...And away we go!

# Declare static variables:

user=$USER

host=$HOSTNAME

# Check for less and rsync, install if needed:

dpkg -l | grep -qw rsync || sudo apt install rsync -yyq
dpkg -l | grep -qw less || sudo apt install less -yyq

# Set functions:

drive_test() {

# This function checks for a usable USB drive.

# Checking for any USB drive:

if [[ ! $(lsblk -S -o  TRAN | grep 'usb') = *usb* ]]; then

    echo $'\n'$"BU Error: No USB drive connected!" >&2
    echo "- Check to see that BU_Drive is plugged in." >&2
    echo "- Please run 'bu --help' to learn about drive setup. :)" >&2
    exit 1

fi

# Checking for a USB drive that is setup for BU:

if [ ! -d /media/$user/BU_Drive ]; then

    echo $'\n'$"BU Error: No USB drive with a partition labeled "BU_Drive!"" >&2
    echo "- The drive(s) you have plugged in are not ready for use with BU." >&2
    echo "- Don't launch BU as root or with 'sudo bu.'" >&2
    echo "- Please run 'bu --help' to learn about drive setup. :)" >&2
    exit 1

fi

}

backup() {

# Check for sudo privileges:

echo "Checking for sudo privileges..."
sudo ls >/dev/null

# Making sure user has ownership of the BU_Drive:

echo "Changing ownership of BU_Drive to $user..."
sudo chown $user /media/${user}/BU_Drive/

# Creating machine specific directories:
echo "Checking for/creating machine specific directories..."
mkdir -p /media/$user/BU_Drive/BU_Backups/$host

# Check if directory for host machine was successfully created:

if [ "$?" == "0" ]; then

    echo "...Done. BU_Drive is ready."

else

    echo $'\n'$"BU Error: Could not create directory for $host!" >&2
    echo "- Backup aborted. Check the status of the BU_Drive." >&2
    exit -1
fi

# Run rsync command:

echo "Backing up /etc and /home to BU_Drive/BU_Backups/$host/..."
sudo rsync -aH --delete --info=progress2 /etc /home \
/media/$user/BU_Drive/BU_Backups/$host/

# Check for status of backup and exit:

if [ "$?" == "0" ]; then

    # Clear any accidental input during backup:
    read -t 1 -n 10000 discard
    echo "------------------"
    echo "- All backed up! -"
    echo "------------------"
    echo "Wait! Syncing Drives..."
    sync
    echo "...done"
    echo "It's safe to remove the USB drive now."
    exit

else

    # Clear any accidental input during backup:
    read -t 1 -n 10000 discard
    echo "There were errors! Try running the command again to correct them." >&2
    echo "- If errors persist then you may have corrupt files or failing hardware." >&2
    exit 1

fi

}

restore() {

# Runs an rsync operation to restore host's /home directory.

# Check for the host's backup directory:

if [ ! -d /media/$user/BU_Drive/BU_Backups/$host/ ]; then

    echo "BU Error: Cannot find valid backup directory for $host!" >&2
    echo "- This drive may not have been used to backup this machine." >&2
    echo "- BU_Backups/$host directory may have been moved or deleted." >&2
    echo "- Hostname or username may have changed since last backup." >&2
    exit 1

fi

echo $'\n'$"BU Restore Function (Version 1.0)"
echo $'\n'$"WARNING!"
echo "Any new files created in /home since last backup WILL BE DELETED!"
echo "Are you sure you want to restore now? [y/N]"
read -n 1 -s choice

    if [ "$choice" == "y" ]; then

        # Giving user a chance to close other apps and starting rsync.

        echo "Close any running applications and press any key to continue."
        read -n 1 -s
        echo $'\n'$"Restoring /home... Please DO NOT open any applications."
        sudo rsync -aH --delete --info=progress2 \
        /media/$user/BU_Drive/BU_Backups/$host/home/ /home/

            # Checking status of rsync exit code:

            if [ "$?" == "0" ]; then

                # Prompt user to restart machine and exit:

                # Clear any accidental input during restore:
                read -t 1 -n 10000 discard
                echo "-------------------------"
                echo "- Restoration Complete! -"
                echo "-------------------------"
                echo "Wait! Syncing drives..."
                sync
                echo "...Done."
                echo "It's now safe to remove BU_Drive."
                echo "Restart machine for all changes to take effect."
                exit

            else

                # Returning to Main Menu if rsync fails:

                # Clear any accidental input during restore:
                read -t 1 -n 10000 discard
                echo $'\n'$"BU Error: rsync exited with errors!" >&2
                echo "DO NOT DO ANYTHING UNTIL YOU:" >&2
                echo $'\n'$"    Make sure BU_Drive USB is still plugged in." >&2
                echo "    Remount BU_Drive USB by unplugging it and plugging it back in." >&2
                echo $'\n'$"Wait a few seconds and try running 'bu --restore' again." >&2
                echo "You may need to manually restore your data if errors persist." >&2
                exit 1

            fi

    else

        echo "Restoration canceled."
        exit

    fi

}

help() {

# Print help information using less utility:

less << _EOF_

 BU - USB Backup Tool (Version 1.0) -- Help
 (v. 1.0)

 Press "q" to exit this Help page.

 Commands:

 bu = Fully backs up host's /etc and /home directories to BU_Drive.
 bu --help = Prints this help information.
 bu --restore = Accesses BU Restore function.

 Description:

 BU is a program that makes keeping all of your user data safely backed up on
 a dedicated External USB drive easy.

 BU will update files that have changed, remove files that have been
 deleted and add any new files that have been created since the last backup.
 The initial backup can take a lot of time if you have a lot of data stored
 in your system's /home directory. BU creates a directory with the host name
 of the machine it's backing up from inside BU_Backups. This allows users to
 share one BU_Drive with multiple machines.

 The directory structure and all files are stored openly to allow users easy
 access if they only need to retrieve a few files or directories using a file
 manager.

 The BU Restore function is an interactive tool that let's users restore their
 /home directories to a backup up state. This function will only work when
 restoring to a machine with the exact same hostname as the one the backs were
 made from. It is intended for emergency use, as when significant number of
 directories and files are accidentally removed from /home.

 BU_Drive Setup

 You need to prepare a BU Drive with a tool like Gparted or Disks.
 This can be any USB storage device. The dedicated USB drive MUST contain a
 partition formatted with a Linux native file system such as Ext4 or XFS. The
 partition MUST be labeled "BU_Drive" so BU can find it and use it for backups.
 The partition needs to have enough free capacity to store all data in /home on
 all of the machines you want to use the drive for. Note: You will get many
 errors if you attempt to use BU to backup to a partition that is formatted with
 non-native file systems like FAT32 or NTFS. 

 Disclaimer:

 THIS SOFTWARE IS PROVIDED BY EZEELINUX “AS IS” AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL EZEELINUX BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

_EOF_

}

# Execution.

# Checking for command line arguments:

if [ "$1" == "--help" ]; then
	help
	exit
fi

if [ "$1" == "--restore" ]; then
	drive_test
	restore
fi

if  [ -n "$1"  ]; then
    echo "BU Error: Invalid argument. " >&2
    echo "- Try 'bu --help' to see the available commands. :)" >&2
    exit 1
fi

# Tell 'em who we are...

echo "BU -- USB Backup Tool (Version 1.0)"
drive_test
backup
