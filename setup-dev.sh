# Define space for new SSD partitions
ssd_boot_start_mb=1 \
ssd_boot_end_mb=512 \
\
ssd_swap_start_mb=$(($ssd_boot_end_mb + 1)) \
ssd_swap_end_mb=$(($ssd_swap_start_mb + 8 * 1024)) \
\
ssd_data_start_mb=$(($ssd_swap_end_mb + 1)) \
ssd_data_end_mb="100%"

# Make SSD partitions, saving their names
# First, gpt partition table
sudo parted -s /dev/nvme0n1 mklabel gpt

# Then, data
sudo parted -s /dev/nvme0n1 mkpart primary ext4 ${ssd_data_start_mb}MiB ${ssd_data_end_mb}
ssd_data_partition=/dev/nvme0n1p1
sudo mkfs.ext4 -F -L data $ssd_data_partition

# Then, boot
sudo parted -s /dev/nvme0n1 mkpart primary ext4 ${ssd_boot_start_mb}MiB ${ssd_boot_end_mb}MiB
ssd_boot_partition=/dev/nvme0n1p2
sudo parted /dev/nvme0n1 set 2 boot on
sudo mkfs.fat -F 32 -n boot $ssd_boot_partition

# Then, swap
sudo parted -s /dev/nvme0n1 mkpart primary linux-swap ${ssd_swap_start_mb}MiB ${ssd_swap_end_mb}MiB
ssd_swap_partition=/dev/nvme0n1p3
sudo mkswap -L swap $ssd_swap_partition

zfs_pool="rootpool"

# Make ZFS pool
sudo zpool create -f $zfs_pool $ssd_data_partition

# Make ZFS datasets
zfs_pool_root="$zfs_pool/root" \
zfs_pool_nix="$zfs_pool/nix"

sudo zfs create -o mountpoint=legacy $zfs_pool_root
sudo zfs create -o mountpoint=legacy $zfs_pool_nix

# Mount ZFS datasets
sudo mkdir -p /mnt
sudo mount -t zfs $zfs_pool_root /mnt

sudo mkdir -p /mnt/nix
sudo mount -t zfs $zfs_pool_nix /mnt/nix

# Mount boot partition
sudo mkdir -p /mnt/boot
sudo mount $ssd_boot_partition /mnt/boot

# Generate config
sudo nixos-generate-config --root /mnt

# Download the flake
mkdir -p /mnt/etc/nixos
sudo curl -o /mnt/etc/nixos/flake.nix https://raw.githubusercontent.com/spiralblue/jetson-base-flake/master/_remote_flake.nix

# Install nixos
sudo nixos-install --root /mnt --flake /mnt/etc/nixos#jetson-dev
