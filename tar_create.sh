#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=tarcreate
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --output=<LOG-PATH>/tarcreate.%j.o
#SBATCH --error=<LOG-PATH>/tarcreate.%j.o
#SBATCH --mem=6GB
#SBATCH --time=12:00:00
#SBATCH --mail-user=<EMAIL>
#SBATCH --mail-type=ALL

cd <ZARR-FILE>
for var in u v w temp qc qv qi qr cloud_num tke theta_v pres rho div;
       do
               echo $var
               tar_creator -i ${var}/ -t <ZARR-FILENAME-WITHOUT-ENDING>.${var}.{:03d}.tar -s 33554432000
       done

tar_creator -i time height height_bnds .zmetadata .zattrs .zgroup -t <ZARR-FILENAME-WITHOUT-ENDING>.coords.{:03d}.tar -s 33554432000

for var in u v w temp qc qv qi qr cloud_num tke theta_v pres rho div coords;
do
        echo $var
        tar_referencer -t <ZARR-FILENAME-WITHOUT-ENDING>.${var}.???.tar -p <ZARR-FILENAME-WITHOUT-ENDING>.${var}.tar.preffs
done

#in a last step the preffs files need to be combined
