# Born2BeRoot

## Project Overview

Born2BeRoot is a Linux system administration project focused on deploying a secure server inside a virtual machine. Instead of writing application code, the project requires configuring the operating system itself according to predefined security and administration requirements.

The project introduces:

- Linux administration
- system services
- filesystem hierarchy
- logical volume management (LVM)
- user management
- sudo
- SSH
- firewalls
- cron
- bash scripting
- security hardening

## Project Objectives

The completed project must:

- Install Debian without a graphical interface.
- Partition the storage using encrypted Logical Volume Management (LVM).
- Configure secure remote administration through SSH.
- Restrict network access using UFW.
- Enforce strong password policies.
- Configure sudo with logging and security restrictions.
- Create and manage users and groups.
- Automate system monitoring using cron and shell scripting.

The objective is to build a secure Debian server inside a virtual machine while configuring the operating system manually.

> **Note**
>
> This repository is intended as a technical reference and documentation of the project rather than a step-by-step tutorial. It explains the concepts, configuration, and rationale behind each component, but it does not provide a complete walkthrough from start to finish.

---

## System configuration

### Disk Partitions and Filesystem Layout

The installation separates different categories of data into dedicated partitions and logical volumes. This improves organization, simplifies administration, enhances security, and prevents one part of the system from exhausting all available disk space.

Linux represents every storage device as a file under the `/dev` directory.

Examples include:

| Device | Description |
|---------|-------------|
| `/dev/sda` | First SATA/SCSI hard drive or SSD |
| `/dev/sdb` | Second SATA/SCSI drive |
| `/dev/sdc` | Third SATA/SCSI drive |
| `/dev/nvme0n1` | First NVMe SSD |
| `/dev/nvme1n1` | Second NVMe SSD |

> [!NOTE]
> Historically, hard drives and SATA SSDs are named `sdX`, while modern NVMe solid-state drives use the `nvmeXnY` naming convention.

Useful commands for listing storage devices:

* Displays the complete storage hierarchy.

```bash
lsblk
```

* Displays devices together with filesystems, UUIDs, and mount points.

```bash
lsblk -f
```

* Lists only physical storage devices, showing their names, capacities, and hardware models.

```bash
lsblk -d -o NAME,SIZE,MODEL
```

---

#### Partition Layout Used in This Project

The virtual machine contains a single virtual disk.

```
/dev/sda
├── sda1   /boot
├── sda2   Extended Partition
└── sda5   LVM Physical Volume
```

> [!NOTE]
> `/boot` is intentionally left outside LVM and remains unencrypted because the firmware and bootloader must load the Linux kernel before encrypted storage can be unlocked.

The remaining disk space is allocated to LVM, where multiple logical volumes are created for different filesystem mount points.

```
sda
├── sda1          /boot
├── sda2
└── sda5
     └── crypt
          └── LVMGroup
               ├── root
               ├── home
               ├── var
               ├── srv
               ├── tmp
               ├── var-log
               └── swap
```

---

#### Logical Volume (LV)

Logical Volumes behave like traditional disk partitions. Unlike normal partitions, they can be resized, extended, or reduced without modifying the underlying disk layout. This flexibility is the primary advantage of LVM.

Common operations include:

- Creating logical volumes
- Extending logical volumes
- Reducing logical volumes
- Removing logical volumes
- Taking snapshots

After a logical volume is created, a filesystem is placed on it using `mkfs`, and the volume is mounted into the Linux filesystem hierarchy.

---

#### LVM Layout Used in This Project

The project creates dedicated logical volumes for:

- `/`
- `/home`
- `/var`
- `/var/log`
- `/srv`
- `/tmp`
- `swap`

Separating these directories prevents one area of the system from consuming all available storage and simplifies future maintenance.

> [!NOTE]
> **Logical Volume Management (LVM)** is a storage management layer that sits between disk partitions and filesystems. Instead of creating filesystems directly on a partition, LVM groups storage into a **Volume Group (VG)** and allocates it to multiple **Logical Volumes (LVs)**. In this project, a single encrypted partition is used as an LVM Physical Volume, from which separate logical volumes are created for `/`, `/home`, `/var`, `/srv`, `/tmp`, `/var/log`, and `swap`.

---

#### Filesystem Layout

Linux follows the **Filesystem Hierarchy Standard (FHS)**, which defines the purpose of standard directories within the operating system.

Instead of placing the entire operating system on a single partition, the project creates a single LVM Volume Group from the encrypted partition. Storage from this Volume Group is allocated to multiple Logical Volumes, each dedicated to a specific mount point such as /, /home, /var, /srv, and /tmp.

|  Mount Point	| Purpose |
|---------------|---------|
| `/boot`	| Stores GRUB, Linux kernel, and initramfs used during boot. |
| `/`		| Root filesystem containing the operating system and essential system files. |
| `/home`	| Personal files and configuration for user accounts. |
| `/var`	| Variable data such as package caches, databases, mail, and logs. |
| `/var/log`	| Dedicated storage for system and application log files. Prevents excessive logging from filling the `/var` filesystem. |
| `/srv`	| Data served by network services such as FTP or web servers. |
| `/tmp`	| Temporary files created by applications and the operating system. |
| `swap`	| Disk space used as virtual memory when physical RAM becomes insufficient. |

Separating these directories provides several advantages:

- prevents logs from filling the root filesystem
- isolates user data from operating system files
- simplifies backups
- improves security by limiting the impact of storage exhaustion
- allows individual logical volumes to be resized independently using LVM


---

### Users and Groups

Linux is a multi-user operating system, meaning multiple users can exist simultaneously, each with their own account, permissions, home directory, and running processes. Every action performed on the system is associated with a user account, allowing the operating system to enforce access control and maintain accountability.

Each user is assigned a unique **User ID (UID)**, while every group has a **Group ID (GID)**. Instead of assigning permissions to individual users, Linux commonly grants permissions to groups. This simplifies administration by allowing multiple users to inherit the same privileges through group membership.

The Linux permission model associates every file and directory with:

- an owner (user)
- an owning group
- permission bits for the owner, group, and all other users

This model determines who can read, write, or execute files and directories.

#### System Users

Several accounts exist on a typical Linux system:

|   User       | Purpose |
|--------------|---------|
|  `root`      | Superuser with unrestricted administrative privileges. |
| System users | Service accounts used by daemons and applications (e.g. `www-data`, `daemon`, `systemd-network`). These accounts generally cannot log in interactively. |
| Regular users | Human users with limited privileges for everyday tasks. |

> [!NOTE]
> Following the principle of least privilege, administrative work should be performed through `sudo` rather than by logging in directly as the `root` user.

#### Groups

Administrative groups in this project:

|   Group   | Purpose |
|-----------|---------|
| `sudo`    | Allows members to execute commands with elevated privileges via `sudo`. |
| `user42`  | Project-specific group required by the Born2BeRoot subject. |

A user may belong to multiple groups simultaneously, inheriting the permissions granted by each.

#### Common Administration Commands

| Command | Purpose |
|---------|---------|
| `whoami` | Display the current user. |
| `id <user>` | Display a user's UID, GID, and group memberships. |
| `groups <user>` | List the groups a user belongs to. |
| `useradd` / `adduser` | Create a new user account. |
| `passwd <user>` | Set or change a user's password. |
| `groupadd` | Create a new group. |
| `usermod -aG <group> <user>` | Add an existing user to a supplementary group. |
| `getent passwd` | List user accounts from the system databases. |
| `getent group` | List defined groups. |


---

### Password Policy

A password policy defines the rules users must follow when creating and maintaining passwords. Its primary objective is to reduce the risk of unauthorized access by enforcing strong passwords, limiting password reuse, and requiring periodic password changes.

Linux implements password policies through two complementary mechanisms:

- **PAM (Pluggable Authentication Modules)** validates password complexity during password creation or modification.
- **Password aging** enforces expiration, minimum lifetime, and warning periods through account settings.

#### Pluggable Authentication Modules (PAM)

PAM is a modular authentication framework used by Linux applications such as `login`, `passwd`, `sudo`, and `sshd`. Rather than implementing authentication independently, these applications rely on PAM to enforce a centralized security policy.

The Born2BeRoot subject requires the following password policy:

| Requirement | Value |
|------------|-------|
| Minimum password length | **10 characters** |
| Uppercase letters | At least **1** |
| Numeric characters | At least **1** |
| Consecutive identical characters | Maximum **3** |
| Username in password | Not allowed |
| Password expiration | **30 days** |
| Minimum password lifetime | **2 days** |
| Expiration warning | **7 days** before expiration |
| Password history | Root password must differ from the previous password by at least **7 characters** |

#### Configuration Files

The password policy is primarily configured through:
`/etc/pam.d/common-password`

---

### SSH (Secure Shell)

Secure Shell (SSH) is a network protocol used to securely access and administer remote systems over an untrusted network. It replaces older protocols such as Telnet by encrypting all communication between the client and server, preventing passwords and transmitted data from being intercepted.

SSH follows a client-server architecture:

```
SSH Client
      │
Encrypted Connection
      │
SSH Server (sshd)
      │
Linux Shell
```

After a connection is established, the user can execute commands, transfer files, or manage the system remotely as if working directly on the machine.

#### SSH Components

SSH consists of two primary components:

| Component | Purpose |
|----------|---------|
| **SSH Client (`ssh`)** | Initiates a secure connection to a remote server. |
| **SSH Server (`sshd`)** | Listens for incoming SSH connections and authenticates users. |

The SSH server runs as a background service (daemon) and continuously waits for incoming connection requests on a configured network port.

#### Project Requirements

The Born2BeRoot subject requires the SSH service to be configured as follows:

- The SSH daemon must listen **only on port 4242**.
- **Direct root login must be disabled** (`PermitRootLogin no`).
- Remote administration must be performed using a regular user account.
- Password authentication is enabled to satisfy the project requirements.
- Only port **4242** is permitted through the firewall.

Disabling direct root login follows the principle of least privilege, ensuring administrative access is obtained through a regular user account with `sudo` privileges rather than by exposing the superuser account directly.

#### Configuration Files

The primary SSH configuration file is:

| File | Purpose |
|------|---------|
| `/etc/ssh/sshd_config` | Configures the SSH daemon, including listening port, authentication methods, and login restrictions. |

After modifying the configuration, the SSH service must be restarted for changes to take effect.

#### Verification

Useful commands for verifying the SSH configuration include:

| Command | Purpose |
|---------|---------|
| `systemctl status ssh` | Verify that the SSH service is running. |
| `ss -tlnp \| grep 4242` | Confirm that `sshd` is listening on port 4242. |
| `ssh <user>@<ip> -p 4242` | Connect to the server using the configured port. |
| `grep -E "Port\|PermitRootLogin\|PasswordAuthentication" /etc/ssh/sshd_config` | Display the relevant SSH configuration directives. |

During the evaluation, the SSH configuration is typically verified by attempting to connect to the virtual machine on port **4242** and confirming that direct login as `root` is rejected while a regular user can authenticate successfully.

---

### UFW Firewall

A firewall is a network security mechanism that monitors and filters incoming and outgoing network traffic according to a predefined set of rules. Its primary purpose is to prevent unauthorized network access while allowing legitimate communication.

On Linux, packet filtering is performed by the kernel through **netfilter**. Traditionally, firewall rules are managed using **iptables**, while modern Linux distributions increasingly use **nftables**. **UFW (Uncomplicated Firewall)** provides a simplified command-line interface for managing these firewall rules without requiring direct interaction with the underlying packet filtering framework.

By default, UFW follows a **default deny** security model: unsolicited incoming connections are blocked unless an explicit rule permits them.

#### Project Requirements

The Born2BeRoot subject requires the firewall to be configured so that:

- all incoming connections are denied by default
- outgoing connections are allowed
- only **TCP port 4242** is open for SSH and any other added services (FTP server, Wordpress, etc.)

#### Firewall Rules

Firewall rules determine how the system handles network traffic based on criteria such as:

- protocol (TCP or UDP)
- source or destination IP address
- port number
- connection state

Rules are evaluated to decide whether traffic should be accepted or rejected before it reaches the application.

#### Configuration

Typical UFW configuration:

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow 4242/tcp
ufw enable
```

Once enabled, the firewall filters all network traffic according to the configured rules.

#### Verification

Useful commands for verifying the firewall configuration include:

| Command | Purpose |
|---------|---------|
| `ufw status` | Display whether UFW is enabled and list active rules. |
| `ufw status numbered` | Display active firewall rules with rule numbers. |
| `ufw app list` | List available application profiles. |
| `ss -tln` | Display listening TCP ports. |

Expected output:

```
Status: active

To                         Action      From
--                         ------      ----
4242/tcp                   ALLOW       Anywhere
4242/tcp (v6)              ALLOW       Anywhere (v6)
```

---

### Sudo Configuration

`sudo` (superuser do) provides a controlled mechanism for delegating administrative privileges without requiring users to log in directly as `root`. Instead of granting unrestricted superuser access, `sudo` enforces authentication, authorization, auditing, and policy-based privilege escalation. This follows the **principle of least privilege**, allowing users to perform administrative tasks only when necessary while maintaining a complete audit trail.

Compared to logging in as `root`, `sudo` offers several operational and security advantages:

* records administrative activity for auditing and incident analysis
* requires user authentication before privilege escalation
* limits privileged access through configurable policies
* reduces the risk of accidental or unauthorized system modifications
* provides accountability by associating privileged actions with individual users

#### Project Requirements

The Born2beroot project requires the following `sudo` configuration:

* limit authentication to **three password attempts**
* define a **custom authentication failure message**
* enable **input and output logging**
* enforce **TTY usage** for privileged commands
* configure a **secure executable path**
* store `sudo` logs in a **dedicated log file**

For this project, `sudo` is configured according to the project requirements while following common Linux system administration practices.

#### Project Configuration

The following `sudo` options are configured:

| Setting                                        | Purpose                                                                                                                                                                             |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Three authentication attempts**              | Limits password retries to reduce brute-force attempts while allowing reasonable user error.                                                                                        |
| **Custom error message**                       | Displays a predefined message when authentication fails, satisfying project requirements and providing consistent feedback.                                                         |
| **Input logging**                              | Records terminal input during privileged sessions, enabling administrators to review executed commands and user interactions.                                                       |
| **Output logging**                             | Captures command output for auditing, troubleshooting, and forensic analysis.                                                                                                       |
| **TTY enforcement (`requiretty`)**             | Requires `sudo` to be executed from a real terminal, preventing privilege escalation from non-interactive contexts where appropriate.                                               |
| **Restricted executable path (`secure_path`)** | Uses a predefined list of trusted directories when executing privileged commands, preventing malicious or unintended executables from being run through manipulated `$PATH` values. |
| **Centralized sudo log file**                  | Stores authentication attempts and privileged activity in a dedicated log file, simplifying monitoring, auditing, and log management.                                               |

---

### Cron

`cron` is the standard time-based job scheduler on Unix and Linux systems. It runs background tasks automatically at predefined dates and times without user intervention. The `cron` daemon continuously monitors scheduled jobs defined in **crontab** (cron table) files and executes them according to their schedule.

Common uses of `cron` include:

* system maintenance and housekeeping
* automated backups
* log rotation and cleanup
* software updates
* monitoring and health checks
* scheduled reports and notifications
* execution of custom administrative scripts

#### Project Requirements

The Born2beroot project requires:

* configuring a **cron job** that runs every **10 minutes**
* executing the `monitoring.sh` script automatically
* broadcasting the script's output to **all logged-in terminals** using the `wall` command

This project's configuration demonstrates the use of Linux task scheduling to automate system monitoring and provide continuous operational visibility without manual intervention.

#### Cron configuration

Cron jobs are stored in different locations depending on how they are configured. For the Born2beroot project, the cron job is configured using root's crontab.

Common locations are:

```
File/Location	Purpose
-----------------------------------------------
/var/spool/cron/crontabs/root (Debian/Ubuntu)	Root user's crontab (managed via crontab -e; do not edit directly).
/etc/crontab	System-wide crontab with an additional field specifying the user to run the command as.
/etc/cron.d/	Directory for package- or administrator-defined cron jobs. Each file follows the /etc/crontab format.
```

Set up cron job:
```bash
sudo crontab -e
```

Verify the configured cron jobs:
```bash
sudo crontab -l
```

#### Cron's job (task)

As required by the Born2beroot project, a cron job executes the `monitoring.sh` script every **10 minutes** while the system is running.

The script gathers key system information and broadcasts the results to all currently logged-in users using the `wall` command. This provides administrators and users with periodic visibility into the system's current state without requiring manual execution.

Typical information displayed includes:

* system architecture and kernel version
* physical and virtual CPU statistics
* memory and disk usage
* CPU load
* last system boot time
* active TCP connections
* logged-in users
* LVM status
* number of executed `sudo` commands
* IPv4 address
* MAC address

#### How Cron Works

Cron schedules jobs using five time fields followed by the command to execute:

```text
* * * * * command
│ │ │ │ │
│ │ │ │ └── Day of week (0–7)
│ │ │ └──── Month (1–12)
│ │ └────── Day of month (1–31)
│ └──────── Hour (0–23)
└────────── Minute (0–59)
```

For this project, the schedule executes the monitoring script every ten minutes:

```bash
*/10 * * * * /path/to/monitoring.sh
```

The expression `*/10` instructs cron to run the command every ten minutes regardless of the hour, day, or month.

#### Security and Administration Considerations

Cron jobs execute with the permissions of the user who owns the crontab. For administrative tasks, jobs are typically configured under the `root` account, allowing access to privileged system information and maintenance operations.

When creating scheduled tasks, administrators should:

* use absolute paths for commands and scripts
* ensure scripts have appropriate execution permissions
* redirect output to log files or `/dev/null` when appropriate
* avoid unnecessary root privileges whenever possible
* thoroughly test scripts before scheduling them
* keep scheduled tasks lightweight to prevent excessive system load
