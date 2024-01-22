# Get newly flashed EMMC info
last_emmc_sector=$(sudo fdisk -l /dev/mmcblk0 | grep "^/dev/mmcblk0p" | awk '{print $2}' | sort -n | head -n 1) \
emmc_sector_size=$(cat /sys/block/mmcblk0/queue/physical_block_size) \
emmc_space_bytes=$(($last_emmc_sector * $emmc_sector_size)) \
emmc_space_mb=$((emmc_space_bytes / 1024 / 1024))

# Define space for new EMMC partitions
emmc_boot_start_mb=1 \
emmc_boot_end_mb=512 \
emmc_root_start_mb=$(($emmc_boot_end_mb + 1)) \
emmc_root_end_mb=$(($emmc_space_mb - 1))

# Define space for new SSD partitions
root_mirror_size_mb=$(($emmc_root_end_mb - $emmc_root_start_mb + 1)) \
ssd_root_start_mb=1 \
ssd_root_end_mb=$root_mirror_size_mb \
ssd_swap_start_mb=$(($ssd_root_end_mb + 1)) \
ssd_swap_end_mb=$(($ssd_swap_start_mb + 8 * 1024)) \
ssd_data_start_mb=$(($ssd_swap_end_mb + 1)) \
ssd_data_end_mb="100%"

# No need to format EMMC, it's pre-formatted

# Make EMMC partitions, saving their names. The names aren't deterministic as there are existing partitions after flashing.
# First, boot
ls /dev/mmcblk0p* > /tmp/partitions_before.txt
sudo parted -s /dev/mmcblk0 mkpart primary fat32 ${emmc_boot_start_mb}MiB ${emmc_boot_end_mb}MiB
ls /dev/mmcblk0p* > /tmp/partitions_after.txt
emmc_boot_partition=$(diff /tmp/partitions_before.txt /tmp/partitions_after.txt | grep "^>" | awk '{print $2}')
sudo mkfs.fat -F 32 -n boot $emmc_boot_partition

# Then, root
ls /dev/mmcblk0p* > /tmp/partitions_before.txt
sudo parted -s /dev/mmcblk0 mkpart primary ext4 ${emmc_root_start_mb}MiB ${emmc_root_end_mb}MiB
ls /dev/mmcblk0p* > /tmp/partitions_after.txt
emmc_root_partition=$(diff /tmp/partitions_before.txt /tmp/partitions_after.txt | grep "^>" | awk '{print $2}')
# Not naming the partition as it will be used in zfs

# Set boot partition as bootable
emmc_boot_partition_num=$(echo $emmc_boot_partition | grep -o '[0-9]*$')
sudo parted /dev/mmcblk0 set $emmc_boot_partition_num boot on

# Make SSD partitions, saving their names
# First, gpt partition table
sudo parted -s /dev/nvme0n1 mklabel gpt

# Then, data
sudo parted -s /dev/nvme0n1 mkpart primary ext4 ${ssd_data_start_mb}MiB ${ssd_data_end_mb}
ssd_data_partition=/dev/nvme0n1p1
sudo mkfs.ext4 -F -L data $ssd_data_partition

# Then, root
sudo parted -s /dev/nvme0n1 mkpart primary ext4 ${ssd_root_start_mb}MiB ${ssd_root_end_mb}MiB
ssd_root_partition=/dev/nvme0n1p2

# Then, swap
sudo parted -s /dev/nvme0n1 mkpart primary linux-swap ${ssd_swap_start_mb}MiB ${ssd_swap_end_mb}MiB
ssd_swap_partition=/dev/nvme0n1p3
sudo mkswap -L swap $ssd_swap_partition

zfs_pool="rootpool"

# Make ZFS pool
sudo zpool create -f $zfs_pool mirror $ssd_root_partition $emmc_root_partition

# Make ZFS datasets
zfs_pool_root="$zfs_pool/root" \
zfs_pool_nix="$zfs_pool/nix" \
zfs_pool_store="$zfs_pool/nix/store"

sudo zfs create -o mountpoint=legacy $zfs_pool_root
sudo zfs create -o mountpoint=legacy $zfs_pool_nix
sudo zfs create -o mountpoint=legacy $zfs_pool_store

# Mount ZFS datasets
sudo mkdir -p /mnt
sudo mount -t zfs $zfs_pool_root /mnt

sudo mkdir -p /mnt/nix
sudo mount -t zfs $zfs_pool_nix /mnt/nix
sudo mkdir -p /mnt/nix/store
sudo mount -t zfs $zfs_pool_store /mnt/nix/store

# Mount boot partition
sudo mkdir -p /mnt/boot
sudo mount $emmc_boot_partition /mnt/boot

# Mount data partition
sudo mkdir -p /mnt/ssd_root
sudo mount $ssd_data_partition /mnt/ssd_root

# Hardlink (relative) child folders in SSD root to /var and /home
sudo mkdir -p /mnt/ssd_root/var /mnt/ssd_root/home
sudo ln -r -s /mnt/ssd_root/var /mnt/var
sudo ln -r -s /mnt/ssd_root/home /mnt/home

# Generate config
sudo nixos-generate-config --root /mnt
