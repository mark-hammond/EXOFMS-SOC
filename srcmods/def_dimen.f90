! *****************************COPYRIGHT*******************************
! (C) Crown copyright Met Office. All rights reserved.
! For further details please refer to the file COPYRIGHT.txt
! which you should have received as part of this distribution.
! *****************************COPYRIGHT*******************************
!
! Module to declare a structure for array dimension data.
!
! Description:
!   This module contains the declaration of the structure
!   used to store array dimension data in the radiation code.
!
! Code Owner: Please refer to the UM file CodeOwners.txt
! This file belongs in section: Radiance Core
!
!------------------------------------------------------------------------------
MODULE def_dimen

IMPLICIT NONE


TYPE StrDim

  INTEGER :: nd_profile
!   Number of atmospheric profiles
  INTEGER :: nd_layer
!   Number of atmospheric layers
  INTEGER :: nd_layer_clr
!   Number of clear atmospheric layers
  INTEGER :: id_cloud_top
!   Topmost declared cloudy layer
  INTEGER :: nd_2sg_profile
!   Number of flux profiles
  INTEGER :: nd_flux_profile
!   Number of output flux profiles
  INTEGER :: nd_radiance_profile
!   Number of radiance profiles
  INTEGER :: nd_j_profile
!   Number of mean radiance profiles
  INTEGER :: nd_channel
!   Number of spectral channels of output
  INTEGER :: nd_max_order
!   Maximum order of spherical harmonics used
  INTEGER :: nd_direction
!   Number of directions for radiances
  INTEGER :: nd_viewing_level
!   Number levels where the radiance may be calculated
  INTEGER :: nd_sph_coeff
!   Number of spherical coefficients used in determining radiances
  INTEGER :: nd_brdf_basis_fnc
!   Number of BRDF basis functions
  INTEGER :: nd_brdf_trunc
!   Maximum order of BRDF truncation
  INTEGER :: nd_tile_type
!   Number of types of tile
  INTEGER :: nd_aerosol_mode
!   Number of aerosol modes
  INTEGER :: nd_profile_aerosol_prsc
!   Number of profiles of prescribed cloudy optical properties
  INTEGER :: nd_profile_cloud_prsc
!   Number of profiles of prescribed aerosol optical properties
  INTEGER :: nd_opt_level_aerosol_prsc
!   Number of levels of prescribed cloudy optical properties
  INTEGER :: nd_opt_level_cloud_prsc
!   Number of levels of prescribed aerosol optical properties
  INTEGER :: nd_cloud_component
!   Number of components of clouds.
  INTEGER :: nd_cloud_type
!   Number of permitted types of clouds.
  INTEGER :: nd_cloud_representation
!   Number of permitted representations of clouds.
  INTEGER :: nd_column
!   Number of cloudy subcolumns
  INTEGER :: nd_subcol_gen
!   Number of sub-columns generated by cloud generator
  INTEGER :: nd_subcol_req
!   Number of sub-columns required for sampling
  INTEGER :: nd_overlap_coeff
!   Number of overlap coefficients for cloud
  INTEGER :: nd_source_coeff
!   Number of coefficients for two-stream sources
  INTEGER :: nd_region
!   Number of regions in a layer
  INTEGER :: nd_point_tile
!   Number of points with surface tiling
  INTEGER :: nd_tile
!   Number of tiles

END TYPE StrDim


END MODULE def_dimen
