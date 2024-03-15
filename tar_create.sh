#!/bin/bash
#SBATCH --account=mh0010
#SBATCH --job-name=tarcreate
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --output=/scratch/m/m300408/tarcreate.%j.o
#SBATCH --error=/scratch/m/m300408/tarcreate.%j.o
#SBATCH --mem=6GB
#SBATCH --time=11:59:00
#SBATCH --mail-user=hauke.schulz@mpimet.mpg.de
#SBATCH --mail-type=ALL


#tar -cvf - u | split --bytes=32000m --suffix-length=3 --numeric-suffix - /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.u.tar
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.u.tar u
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.v.tar v
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.w.tar w
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.temp.tar temp
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.coords.tar time height height_bnds .zmetadata .zattrs .zgroup
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.qc.tar qc
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.pres.tar pres
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.rho.tar rho
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.qv.tar qv
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.qi.tar qi
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.div.tar div
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.theta_v.tar theta_v
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.cloud_num.tar cloud_num
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.tke.tar tke
#tar -cvf /scratch/m/m300408/tars/EUREC4A_ICON-LES_highCCN_DOM01_3D_native.qr.tar qr

#for var in div; #u v w temp qc qv qi qr cloud_num tke theta_v pres rho div;
#	do
#		echo $var
#		tar_creator -i ${var}/ -t EUREC4A_ICON-LES_highCCN_DOM02_3D_native.${var}.{:03d}.tar -s 33554432000
#	done

#tar_creator -i time height height_bnds .zmetadata .zattrs .zgroup -t EUREC4A_ICON-LES_highCCN_DOM02_3D_native.coords.{:03d}.tar -s 33554432000

for var in div; #u v w temp qc qv qi qr cloud_num tke theta_v pres rho div coords;
do
	echo $var
	tar_referencer -t EUREC4A_ICON-LES_highCCN_DOM02_3D_native.${var}.???.tar -p EUREC4A_ICON-LES_highCCN_DOM02_3D_native.${var}.tar.preffs
done

