! *****************************COPYRIGHT*******************************
! (C) Crown copyright Met Office. All rights reserved.
! For further details please refer to the file COPYRIGHT.txt
! which you should have received as part of this distribution.
! *****************************COPYRIGHT*******************************
!
!  Subroutine to calculate the fluxes assuming random overlap using
!  resorting and rebinning of the k-terms to reduce computational
!  cost.
!
! Method:
!   Combinations of k-terms for two gases are calculated, reordered
!   and rebinned. This is repeated for each gas in the band. Monochromatic
!   calculations are performed for each of the resampled k-terms and the
!   results are summed.
!
!- ---------------------------------------------------------------------
SUBROUTINE solve_band_random_overlap_resort_rebin(ierr                  &
    , control, cld, bound                                               &
!                 Atmospheric Column
    , n_profile, n_layer, i_top, p, t, d_mass                           &
!                 Angular Integration
    , i_angular_integration, i_2stream                                  &
    , n_order_phase, l_rescale, n_order_gauss                           &
    , ms_min, ms_max, i_truncation, ls_local_trunc                      &
    , accuracy_adaptive, euler_factor                                   &
    , i_sph_algorithm, i_sph_mode                                       &
!                 Precalculated angular arrays
    , ia_sph_mm, cg_coeff, uplm_zero, uplm_sol                          &
!                 Treatment of Scattering
    , i_scatter_method                                                  &
!                 Options for solver
    , i_solver                                                          &
    , n_esft_red_in, gpnt_split                                         &
!                 Gaseous Properties
    , i_band, n_gas                                                     &
    , index_absorb, i_band_esft, i_scale_esft, i_scale_fnc              &
    , k_esft, k_esft_layer, w_esft, scale_vector                        &
    , p_reference, t_reference                                          &
    , gas_mix_ratio, gas_frac_rescaled                                  &
    , l_doppler, doppler_correction                                     &
!                 Spectral Region
    , isolir                                                            &
!                 Solar Properties
    , zen_0, solar_irrad                                                &
!                 Infra-red Properties
    , planck_flux_top, planck_flux_bottom                               &
    , diff_planck_band                                                  &
    , l_ir_source_quad, diff_planck_band_2                              &
!                 Surface Properties
    , ls_brdf_trunc, n_brdf_basis_fnc, rho_alb                          &
    , f_brdf, brdf_sol, brdf_hemi                                       &
    , planck_flux_ground                                                &
!                 Tiling of the surface
    , l_tile, n_point_tile, n_tile, list_tile, rho_alb_tile             &
    , planck_flux_tile                                                  &
!                 Optical Properties
    , ss_prop                                                           &
!                 Cloudy Properties
    , l_cloud, i_cloud                                                  &
!                 Cloud Geometry
    , n_cloud_top                                                       &
    , n_region, k_clr, i_region_cloud, frac_region                      &
    , w_free, cloud_overlap                                             &
    , n_column_slv, list_column_slv                                     &
    , i_clm_lyr_chn, i_clm_cld_typ, area_column                         &
!                 Levels for calculating radiances
    , n_viewing_level, i_rad_layer, frac_rad_layer                      &
!                 Viewing Geometry
    , n_direction, direction                                            &
!                 Weighting factor for the band
    , weight_band, l_initial                                            &
!                 Fluxes Calculated
    , flux_direct, flux_down, flux_up                                   &
!                 Calculcated radiances
    , i_direct, radiance                                                &
!                 Calculcated rate of photolysis
    , photolysis                                                        &
!                 Flags for Clear-sky Fluxes
    , l_clear, i_solver_clear                                           &
!                 Clear-sky Fluxes
    , flux_direct_clear, flux_down_clear, flux_up_clear                 &
!                 Tiled Surface Fluxes
    , flux_up_tile, flux_up_blue_tile                                   &
!                 Special Surface Fluxes
    , l_blue_flux_surf, weight_blue                                     &
    , flux_direct_blue_surf                                             &
    , flux_down_blue_surf, flux_up_blue_surf                            &
!                 Dimensions
    , nd_profile, nd_layer, nd_layer_clr, id_ct, nd_column              &
    , nd_flux_profile, nd_radiance_profile, nd_j_profile                &
    , nd_band, nd_species                                               &
    , nd_esft_term, nd_esft_max, nd_scale_variable                      &
    , nd_cloud_type, nd_region, nd_overlap_coeff                        &
    , nd_max_order, nd_sph_coeff                                        &
    , nd_brdf_basis_fnc, nd_brdf_trunc, nd_viewing_level                &
    , nd_direction, nd_source_coeff                                     &
    , nd_point_tile, nd_tile                                            &
    )


  USE realtype_rd, ONLY: RealK
  USE def_control, ONLY: StrCtrl
  USE def_cld,     ONLY: StrCld
  USE def_bound,   ONLY: StrBound
  USE def_ss_prop
  USE rad_pcf
  USE yomhook, ONLY: lhook, dr_hook
  USE parkind1, ONLY: jprb, jpim

  IMPLICIT NONE


! Control options:
  TYPE(StrCtrl),      INTENT(IN)    :: control

! Cloud properties:
  TYPE(StrCld),       INTENT(IN)    :: cld

! Boundary conditions:
  TYPE(StrBound),     INTENT(IN)    :: bound

! Sizes of dummy arrays.
  INTEGER, INTENT(IN) ::                                                &
      nd_profile                                                        &
!       Maximum number of profiles
    , nd_layer                                                          &
!       Maximum number of layers
    , nd_layer_clr                                                      &
!       Size allocated for totally clear layers
    , id_ct                                                             &
!       Topmost declared cloudy layer
    , nd_flux_profile                                                   &
!       Size allocated for profiles in arrays of fluxes
    , nd_radiance_profile                                               &
!       Size allocated for profiles in arrays of radiances
    , nd_j_profile                                                      &
!       Size allocated for profiles in arrays of mean radiances
    , nd_band                                                           &
!       Maximum number of spectral bands
    , nd_species                                                        &
!       Maximum number of species
    , nd_esft_term                                                      &
!       Maximum number of ESFT terms for each gas
    , nd_esft_max                                                       &
!       Maximum number of ESFT terms needed in arrays
    , nd_scale_variable                                                 &
!       Maximum number of scale variables
    , nd_column                                                         &
!       Number of columns per point
    , nd_cloud_type                                                     &
!       Size allocated for cloud types
    , nd_region                                                         &
!       Size allocated for cloudy regions
    , nd_overlap_coeff                                                  &
!       Size allocated for cloudy overlap coefficients
    , nd_max_order                                                      &
!       Size allocated for orders of spherical harmonics
    , nd_sph_coeff                                                      &
!       Size allocated for spherical harmonic coefficients
    , nd_brdf_basis_fnc                                                 &
!       Size allowed for BRDF basis functions
    , nd_brdf_trunc                                                     &
!       Size allowed for orders of BRDFs
    , nd_viewing_level                                                  &
!       Size allocated for levels where radiances are calculated
    , nd_direction                                                      &
!       Size allocated for viewing directions
    , nd_source_coeff                                                   &
!       Size allocated for source coefficients
    , nd_point_tile                                                     &
!       Size allocated for points where the surface is tiled
    , nd_tile
!       Size allocated for surface tiles


! Dummy arguments.
  INTEGER, INTENT(INOUT) ::                                             &
      ierr
!       Error flag

!                 Atmospheric column
  INTEGER, INTENT(IN) ::                                                &
      n_profile                                                         &
!       Number of profiles
    , n_layer                                                           &
!       Number of layers
    , i_top
!       Top of vertical grid
  REAL (RealK), INTENT(IN) ::                                           &
      d_mass(nd_profile, nd_layer)                                      &
!       Mass thickness of each layer
    , p(nd_profile, nd_layer)                                           &
!       Pressure
    , t(nd_profile, nd_layer)
!       Temperature

!                 Angular integration
  INTEGER, INTENT(IN) ::                                                &
      i_angular_integration                                             &
!       Angular integration scheme
    , i_2stream                                                         &
!       Two-stream scheme
    , n_order_phase                                                     &
!       Maximum order of terms in the phase function used in
!       the direct calculation of spherical harmonics
    , n_order_gauss                                                     &
!       Order of gaussian integration
    , ms_min                                                            &
!       Lowest azimuthal order used
    , ms_max                                                            &
!       Highest azimuthal order used
    , i_truncation                                                      &
!       Type of spherical truncation used
    , ia_sph_mm(0: nd_max_order)                                        &
!       Address of spherical coefficient of (m, m) for each m
    , ls_local_trunc(0: nd_max_order)                                   &
!       Orders of truncation at each azimuthal order
    , i_sph_mode                                                        &
!       Mode in which the spherical solver is to be used
    , i_sph_algorithm
!       Algorithm used for spherical harmonic calculation
  LOGICAL, INTENT(IN) ::                                                &
      l_rescale
!       Rescale optical properties
  REAL (RealK) ::                                                       &
      cg_coeff(nd_sph_coeff)                                            &
!       Clebsch-Gordan coefficients
    , uplm_zero(nd_sph_coeff)                                           &
!       Values of spherical harmonics at polar angles pi/2
    , uplm_sol(nd_radiance_profile, nd_sph_coeff)                       &
!       Values of spherical harmonics in the solar direction
    , accuracy_adaptive                                                 &
!       Accuracy for adaptive truncation
    , euler_factor
!       Factor applied to the last term of an alternating series
  REAL (RealK), INTENT(IN) ::                                           &
      weight_band
!       Weighting factor for the current band
  LOGICAL, INTENT(INOUT) ::                                             &
      l_initial
!       Flag to initialize diagnostics

!                 Treatment of scattering
  INTEGER, INTENT(IN) ::                                                &
      i_scatter_method
!       Method of treating scattering

!                 Options for solver
  INTEGER, INTENT(IN) ::                                                &
      i_solver                                                          &
!       Solver used
    , n_esft_red_in
!       Number of reduced terms
  REAL (RealK), INTENT(IN) ::                                           &
      gpnt_split
!       g-coordinate for splitting g-space

!                 Gaseous properties
  INTEGER, INTENT(IN) ::                                                &
      i_band                                                            &
!       Band being considered
    , n_gas                                                             &
!       Number of gases in band
    , index_absorb(nd_species, nd_band)                                 &
!       List of absorbers in bands
    , i_band_esft(nd_band, nd_species)                                  &
!       Number of terms in band
    , i_scale_esft(nd_band, nd_species)                                 &
!       Type of ESFT scaling
    , i_scale_fnc(nd_band, nd_species)
!       Type of scaling function
  LOGICAL, INTENT(IN) ::                                                &
      l_doppler(nd_species)
!       Doppler broadening included
  REAL (RealK), INTENT(IN) ::                                           &
      k_esft(nd_esft_term, nd_band, nd_species)                         &
!       Exponential ESFT terms
    , k_esft_layer(nd_profile, nd_layer, nd_esft_term, nd_species)      &
!       Exponential ESFT terms at actual pressure layer
    , w_esft(nd_esft_term, nd_band, nd_species)                         &
!       Weights for ESFT
    , scale_vector(nd_scale_variable, nd_esft_term, nd_band             &
        , nd_species)                                                   &
!       Absorber scaling parameters
    , p_reference(nd_species, nd_band)                                  &
!       Reference scaling pressure
    , t_reference(nd_species, nd_band)                                  &
!       Reference scaling temperature
    , gas_mix_ratio(nd_profile, nd_layer, nd_species)                   &
!       Gas mass mixing ratios
    , doppler_correction(nd_species)
!       Doppler broadening terms
  REAL (RealK), INTENT(OUT) ::                                          &
      gas_frac_rescaled(nd_profile, nd_layer, nd_species)
!       Rescaled gas mass fractions

!                 Spectral region
  INTEGER, INTENT(IN) ::                                                &
      isolir
!       Spectral region

!                 Solar properties
  REAL (RealK), INTENT(IN) ::                                           &
      zen_0(nd_profile)                                                 &
!       Secants (two-stream) or cosines (spherical harmonics)
!       of the solar zenith angle
    , solar_irrad(nd_profile)
!       Incident solar irradiance in band

!                 Infra-red properties
  LOGICAL, INTENT(IN) ::                                                &
      l_ir_source_quad
!       Use a quadratic source function
  REAL (RealK), INTENT(IN) ::                                           &
      planck_flux_top(nd_profile)                                       &
!       Planckian flux at top
    , planck_flux_bottom(nd_profile)                                    &
!       Planckian flux at bottom
    , diff_planck_band(nd_profile, nd_layer)                            &
!       Thermal source function
    , diff_planck_band_2(nd_profile, nd_layer)
!       2x2nd difference of Planckian in band

!                 Surface properties
  REAL (RealK), INTENT(IN) ::                                           &
      planck_flux_ground(nd_profile)
!       Planckian flux at the surface temperature
  INTEGER, INTENT(IN) ::                                                &
      ls_brdf_trunc                                                     &
!       Order of truncation of BRDFs
    , n_brdf_basis_fnc
!       Number of BRDF basis functions
  REAL (RealK), INTENT(IN) ::                                           &
      rho_alb(nd_profile, nd_brdf_basis_fnc)                            &
!       Weights of the basis functions
    , f_brdf(nd_brdf_basis_fnc, 0: nd_brdf_trunc/2                      &
        , 0: nd_brdf_trunc/2, 0: nd_brdf_trunc)                         &
!       Array of BRDF basis terms
    , brdf_sol(nd_profile, nd_brdf_basis_fnc, nd_direction)             &
!       The BRDF evaluated for scattering from the solar
!       beam into the viewing direction
    , brdf_hemi(nd_profile, nd_brdf_basis_fnc, nd_direction)
!       The BRDF evaluated for scattering from isotropic
!       radiation into the viewing direction

! Variables related to tiling of the surface
  LOGICAL, INTENT(IN) ::                                                &
      l_tile
!       Logical to allow invoke options
  INTEGER, INTENT(IN) ::                                                &
      n_point_tile                                                      &
!       Number of points to tile
    , n_tile                                                            &
!       Number of tiles used
    , list_tile(nd_point_tile)
!       List of points with surface tiling
  REAL (RealK), INTENT(IN) ::                                           &
      rho_alb_tile(nd_point_tile, nd_brdf_basis_fnc, nd_tile)           &
!       Weights for the basis functions of the BRDFs
!       at the tiled points
    , planck_flux_tile(nd_point_tile, nd_tile)
!       Local Planckian fluxes on surface tiles

!                 Optical properties
  TYPE(STR_ss_prop), INTENT(INOUT) :: ss_prop
!       Single scattering properties of the atmosphere

!                 Cloudy properties
  LOGICAL, INTENT(IN) ::                                                &
      l_cloud
!       Cloud enabled
  INTEGER, INTENT(IN) ::                                                &
      i_cloud
!       Cloud scheme used

!                 Cloud geometry
  INTEGER, INTENT(IN) ::                                                &
      n_cloud_top                                                       &
!       Topmost cloudy layer
    , n_region                                                          &
!       Number of cloudy regions
    , k_clr                                                             &
!       Index of clear-sky region
    , i_region_cloud(nd_cloud_type)
!       Regions in which types of clouds fall

! Cloud geometry
  INTEGER, INTENT(IN) ::                                                &
      n_column_slv(nd_profile)                                          &
!       Number of columns to be solved in each profile
    , list_column_slv(nd_profile, nd_column)                            &
!       List of columns requiring an actual solution
    , i_clm_lyr_chn(nd_profile, nd_column)                              &
!       Layer in the current column to change
    , i_clm_cld_typ(nd_profile, nd_column)
!       Type of cloud to introduce in the changed layer
  REAL (RealK), INTENT(IN) ::                                           &
      w_free(nd_profile, id_ct: nd_layer)                               &
!       Clear-sky fraction
    , cloud_overlap(nd_profile, id_ct-1: nd_layer                       &
        , nd_overlap_coeff)                                             &
!       Coefficients for transfer for energy at interfaces
    , area_column(nd_profile, nd_column)                                &
!       Areas of columns
    , frac_region(nd_profile, id_ct: nd_layer, nd_region)
!       Fractions of total cloud occupied by each region



!                   Viewing Geometry
  INTEGER, INTENT(IN) ::                                                &
      n_direction
!       Number of viewing directions
  REAL (RealK), INTENT(IN) ::                                           &
      direction(nd_radiance_profile, nd_direction, 2)
!       Viewing directions
  INTEGER, INTENT(IN) ::                                                &
      n_viewing_level                                                   &
!       Number of levels where radiances are calculated
    , i_rad_layer(nd_viewing_level)
!       Layers in which radiances are calculated
  REAL (RealK), INTENT(IN) ::                                           &
      frac_rad_layer(nd_viewing_level)
!       Fractions below the tops of the layers

!                 Flags for clear-sky calculations
  LOGICAL, INTENT(IN) ::                                                &
      l_clear
!       Calculate clear-sky properties
  INTEGER, INTENT(IN) ::                                                &
      i_solver_clear
!       Clear solver used

!                 Calculated Fluxes
  REAL (RealK), INTENT(OUT) ::                                          &
      flux_direct(nd_flux_profile, 0: nd_layer)                         &
!       Direct flux
    , flux_down(nd_flux_profile, 0: nd_layer)                           &
!       Total downward flux
    , flux_up(nd_flux_profile, 0: nd_layer)
!       Upward flux

!                   Calculated radiances
  REAL (RealK), INTENT(INOUT) ::                                        &
      i_direct(nd_radiance_profile, 0: nd_layer)                        &
!       Direct solar irradiance on levels
    , radiance(nd_radiance_profile, nd_viewing_level                    &
        , nd_direction)
!       Radiances

!                   Calculated mean radiances
  REAL (RealK), INTENT(INOUT) ::                                        &
      photolysis(nd_j_profile, nd_viewing_level)
!       Rates of photolysis

!                 Clear-sky fluxes calculated
  REAL (RealK), INTENT(INOUT) ::                                        &
      flux_direct_clear(nd_flux_profile, 0: nd_layer)                   &
!       Clear-sky direct flux
    , flux_down_clear(nd_flux_profile, 0: nd_layer)                     &
!       Clear-sky total downward flux in band
    , flux_up_clear(nd_flux_profile, 0: nd_layer)                       &
!       Clear-sky upward flux
    , flux_up_tile(nd_point_tile, nd_tile)                              &
!       Upward fluxes at tiled surface points
    , flux_up_blue_tile(nd_point_tile, nd_tile)
!       Upward blue fluxes at tiled surface points

!                  Special Diagnostics:
  LOGICAL, INTENT(IN) ::                                                &
      l_blue_flux_surf
!       Flag to calculate the blue flux at the surface
  REAL (RealK), INTENT(IN) ::                                           &
      weight_blue
!       Weights for blue fluxes in this band
  REAL (RealK), INTENT(INOUT) ::                                        &
      flux_direct_blue_surf(nd_flux_profile)                            &
!       Direct blue flux at the surface
    , flux_down_blue_surf(nd_flux_profile)                              &
!       Total downward blue flux at the surface
    , flux_up_blue_surf(nd_flux_profile)
!       Upward blue flux at the surface



! Local variables.
  INTEGER                                                               &
      k                                                                 &
!       Loop variable
    , l                                                                 &
!       Loop variable
    , i_profile                                                         &
!       Loop variable
    , i_layer
!       Loop variable
  INTEGER                                                               &
      i_gas_band                                                        &
!       Index of active gas
    , i_gas_pointer(nd_species)                                         &
!       Pointer array for monochromatic ESFTs
    , iex                                                               &
!       Index of ESFT term
    , i_band_esft_mix                                                   &
!       Number of terms in band for two gases combined
    , i_band_esft_mix_red                                               &
!       Current number of terms in band for two gases combined after
!       resorting and rebinning
    , iex_mix                                                           &
!       Index of term for two gases combined
    , iex_mix_red                                                       &
!       Index of term for two gases combined after resorting and
!       rebinning
    , n_esft_red
!       Number of reduced terms
  REAL (RealK) ::                                                       &
      k_esft_mono(nd_species)                                           &
!       ESFT monochromatic exponents
    , k_gas_abs(nd_profile, nd_layer)                                   &
!       Gaseous absorption
    , d_planck_flux_surface(nd_profile)                                 &
!       Difference in Planckian fluxes between the surface and
!       the air
    , flux_inc_direct(nd_profile)                                       &
!       Incident direct flux
    , flux_inc_down(nd_profile)                                         &
!       Incident downward flux
    , dummy_ke(nd_profile, nd_layer)                                    &
!       Dummy array (not used)
    , k_esft_layer_mix(nd_profile, nd_layer,                            &
        nd_esft_max*nd_esft_max)                                        &
!       ESFT monochromatic exponents for the mixture of two gases
    , w_esft_mix(nd_esft_max*nd_esft_max)                               &
!       Weights for the mixture of two gases
    , w_esft_mix_unsort(nd_esft_max*nd_esft_max)                        &
!       Unsorted weights for the mixture of two gases
    , k_esft_layer_mix_red(nd_profile, nd_layer, nd_esft_max)           &
!       Reduced (resorted and rebinned) ESFT monochromatic exponents
!       for the mixture of two gases
    , w_esft_red(nd_esft_max+1)                                         &
!       Current weights for the mixture of two gases
    , glim_mix_red(nd_esft_max+1)                                       &
!       g-coordinate limits for the reduced terms
    , w_esft_target(nd_esft_max)                                        &
!       Target weights when performing rebinning
    , glim_target(nd_esft_max+1)                                        &
!       Target g-coordinate limits for the terms when performing
!       rebinning
    , w_esft_gauleg(nd_esft_max)                                        &
!       Weights using Gauss-Legendre quadrature
    , gpnt_gauleg(nd_esft_max+1)                                        &
!       g-coordinate points using Gauss-Legendre quadrature
    , xl
!       Variable used for transforming Gauss-Legendre quadrature points
!       and weights from [-1,1] to [a,b].

! Monochromatic incrementing radiances:
  REAL (RealK) ::                                                       &
      flux_direct_part(nd_flux_profile, 0: nd_layer)                    &
!       Partial direct flux
    , flux_total_part(nd_flux_profile, 2*nd_layer+2)                    &
!       Partial total flux
    , flux_direct_clear_part(nd_flux_profile, 0: nd_layer)              &
!       Partial clear-sky direct flux
    , flux_total_clear_part(nd_flux_profile, 2*nd_layer+2)
!       Partial clear-sky total flux
  REAL (RealK) ::                                                       &
      i_direct_part(nd_radiance_profile, 0: nd_layer)                   &
!       Partial solar irradiances
    , radiance_part(nd_radiance_profile, nd_viewing_level               &
        , nd_direction)
!       Partial radiances
  REAL (RealK) ::                                                       &
      photolysis_part(nd_j_profile, nd_viewing_level)
!       Partial rates of photolysis
  REAL (RealK) ::                                                       &
      weight_incr                                                       &
!       Weight applied to increments
    , weight_blue_incr
!       Weight applied to blue increments

  INTEGER(KIND=jpim), PARAMETER :: zhook_in  = 0
  INTEGER(KIND=jpim), PARAMETER :: zhook_out = 1
  REAL(KIND=jprb)               :: zhook_handle
  
  CHARACTER(LEN=*), PARAMETER :: RoutineName                            &
    = 'SOLVE_BAND_RANDOM_OVERLAP_RESORT_REBIN'


  IF (lhook) CALL dr_hook(RoutineName,zhook_in,zhook_handle)
  
! Set the number of active gases and initialize the pointers.
  DO k=1, n_gas
    i_gas_pointer(k)=index_absorb(k, i_band)
  END DO
  
! Set target weights using Gaussian quadrature
  n_esft_red = n_esft_red_in
  IF (n_esft_red > 0 .AND. n_gas > 1) THEN
! DEPENDS ON: calc_gauss_weight_90
    CALL calc_gauss_weight_90(ierr, n_esft_red,                         &
      gpnt_gauleg(1:n_esft_red), w_esft_gauleg(1:n_esft_red))
    IF (gpnt_split < 1.0_RealK .AND. gpnt_split > 0.0_RealK) THEN
      xl=0.5_RealK*(gpnt_split - 0.0_RealK)
      w_esft_target(1:n_esft_red) = xl*w_esft_gauleg(1:n_esft_red)
      xl=0.5_RealK*(1.0_RealK - gpnt_split)
      w_esft_target(n_esft_red+1:2*n_esft_red) =                        &
        xl*w_esft_gauleg(1:n_esft_red)
      n_esft_red = 2*n_esft_red
    ELSE
      xl=0.5_RealK
      w_esft_target(1:n_esft_red) = xl*w_esft_gauleg(1:n_esft_red)
    END IF

! Set target weights using weights of gas 1 (major absorber)
  ELSE
    k = 1 ! Gas 1
    i_gas_band=i_gas_pointer(k)
    DO iex=1, i_band_esft(i_band, i_gas_band)
      w_esft_target(iex) = w_esft(iex,i_band,i_gas_band)
    END DO
    n_esft_red = i_band_esft(i_band, i_gas_band)
  END IF

! Calculate limits in g-space for reduced k-coefficients
  glim_target(1) = 0.0_RealK
  DO iex=1,n_esft_red
    glim_target(iex+1) = glim_target(iex) + w_esft_target(iex)
  END DO
  
! Perform rescaling of gas 1. Copy ESFT terms and weights for the gas 1
! into the arrays for the mixture.
  k = 1 ! Gas 1
  i_gas_band=i_gas_pointer(k)
  DO iex=1, i_band_esft(i_band, i_gas_band)
  
!   Store the absorption coefficient
    IF (i_scale_fnc(i_band, i_gas_band) == ip_scale_lookup) THEN
!     In this case gas_frac_rescaled has already been scaled by k
      k_esft_mono(i_gas_band) = 1.0_RealK
    ELSE
      k_esft_mono(i_gas_band) = k_esft(iex, i_band, i_gas_band)
    END IF

!   Rescale the amount of gas for this absorber if required
    IF (i_scale_esft(i_band, i_gas_band) == ip_scale_term) THEN
! DEPENDS ON: scale_absorb
      CALL scale_absorb(ierr, n_profile, n_layer                        &
        , gas_mix_ratio(1, 1, i_gas_band), p, t                         &
        , i_top                                                         &
        , gas_frac_rescaled(1, 1, i_gas_band)                           &
        , k_esft_layer(1, 1, iex, i_gas_band)                           &
        , i_scale_fnc(i_band, i_gas_band)                               &
        , p_reference(i_gas_band, i_band)                               &
        , t_reference(i_gas_band, i_band)                               &
        , scale_vector(1, iex, i_band, i_gas_band)                      &
        , iex, i_band                                                   &
        , l_doppler(i_gas_band)                                         &
        , doppler_correction(i_gas_band)                                &
        , nd_profile, nd_layer                                          &
        , nd_scale_variable                                             &
        )
    END IF
    
!   Calculate the absorption for the gas
    k_gas_abs(:,:)                                                      &
      =k_esft_mono(i_gas_band)*gas_frac_rescaled(:,:,i_gas_band)
    
!   Copy ESFT terms and weights for the gas 1 into the arrays for
!   the mixture
    k_esft_layer_mix_red(:,:,iex) = k_gas_abs(:,:)
  END DO
  
! Set current number of reduced ESFT terms
  i_band_esft_mix_red = i_band_esft(i_band, i_gas_band)
! Set current reduced weights
  w_esft_red(1:i_band_esft_mix_red) =                                   &
    w_esft(1:i_band_esft_mix_red,i_band,i_gas_band)
  
! Loop over gases and combine ESFT terms and weights
  DO k=2,n_gas
    i_gas_band=index_absorb(k, i_band)
    
!   Loop over the ESFT terms of the gas to be added
    DO iex=1, i_band_esft(i_band, i_gas_band)
    
!     Store the absorption coefficient
      IF (i_scale_fnc(i_band, i_gas_band) == ip_scale_lookup) THEN
!       In this case gas_frac_rescaled has already been scaled by k
        k_esft_mono(i_gas_band) = 1.0_RealK
      ELSE
        k_esft_mono(i_gas_band) = k_esft(iex, i_band, i_gas_band)
      END IF

!     Rescale the amount of gas for this absorber if required
      IF (i_scale_esft(i_band, i_gas_band) == ip_scale_term) THEN
! DEPENDS ON: scale_absorb
        CALL scale_absorb(ierr, n_profile, n_layer                      &
          , gas_mix_ratio(1, 1, i_gas_band), p, t                       &
          , i_top                                                       &
          , gas_frac_rescaled(1, 1, i_gas_band)                         &
          , k_esft_layer(1, 1, iex, i_gas_band)                         &
          , i_scale_fnc(i_band, i_gas_band)                             &
          , p_reference(i_gas_band, i_band)                             &
          , t_reference(i_gas_band, i_band)                             &
          , scale_vector(1, iex, i_band, i_gas_band)                    &
          , iex, i_band                                                 &
          , l_doppler(i_gas_band)                                       &
          , doppler_correction(i_gas_band)                              &
          , nd_profile, nd_layer                                        &
          , nd_scale_variable                                           &
          )
      END IF

!     Calculate the absorption for the gas
      k_gas_abs(1:n_profile,1:n_layer) =                                &
        k_esft_mono(i_gas_band)*                                        &
        gas_frac_rescaled(1:n_profile,1:n_layer,i_gas_band)
          
!     Loop over the ESFT terms of the existing mixture and combine with
!     terms for the current gas
      DO iex_mix_red=1,i_band_esft_mix_red    
        iex_mix =                                                       &
          (iex_mix_red - 1)*i_band_esft(i_band,i_gas_band) + iex
        k_esft_layer_mix(1:n_profile,1:n_layer,iex_mix) =               &
          k_esft_layer_mix_red(1:n_profile,1:n_layer,iex_mix_red) +     &
          k_gas_abs(1:n_profile,1:n_layer)
        w_esft_mix_unsort(iex_mix) =                                    &
          w_esft_red(iex_mix_red)*w_esft(iex,i_band,i_gas_band)
      END DO
    END DO
    i_band_esft_mix = i_band_esft_mix_red*i_band_esft(i_band,i_gas_band)
    
!   Loop over all profiles and layers
    k_esft_layer_mix_red = 0.0_RealK
    DO i_profile=1,n_profile
      DO i_layer=1,n_layer
        
        ! Set weights
        w_esft_mix(1:i_band_esft_mix) =                                 &
          w_esft_mix_unsort(1:i_band_esft_mix)
       
! DEPENDS ON: quicksort
!       Reorder ESFT terms and weights
        CALL quicksort(i_band_esft_mix,                                 &
          k_esft_layer_mix(i_profile,i_layer,1:i_band_esft_mix),        &
          w_esft_mix(1:i_band_esft_mix))
         
! DEPENDS ON: rebin_esft_terms
!       Rebin the ESFT terms
        CALL rebin_esft_terms(i_band_esft_mix, n_esft_red,              &
          i_profile, i_layer,                                           &
          w_esft_target, glim_target,                                   &
          k_esft_layer_mix, w_esft_mix,                                 &
          k_esft_layer_mix_red, glim_mix_red,                           &
          nd_profile, nd_layer, nd_esft_max)
      END DO
    END DO
    
!   After inclusion of gas 2 number of reduced ESFT terms and reduced
!   weights must be reset
    i_band_esft_mix_red = n_esft_red
    w_esft_red(1:n_esft_red) = w_esft_target(1:n_esft_red)
  END DO
  
! Loop over final reduced ESFT terms
  DO iex=1,n_esft_red

!   Set the appropriate source terms for the two-stream equations.

    IF ( (i_angular_integration == ip_two_stream).OR.                   &
         (i_angular_integration == ip_ir_gauss) ) THEN

      IF (isolir == ip_solar) THEN

!       Solar region.
        DO l=1, n_profile
          d_planck_flux_surface(l)=0.0e+00_RealK
          flux_inc_down(l)=solar_irrad(l)/zen_0(l)
          flux_inc_direct(l)=solar_irrad(l)/zen_0(l)
        END DO

      ELSE IF (isolir == ip_infra_red) THEN
!       Infra-red region.

        DO l=1, n_profile
          flux_inc_direct(l)=0.0e+00_RealK
          flux_direct_part(l, n_layer)=0.0e+00_RealK
          flux_inc_down(l)=-planck_flux_top(l)
          d_planck_flux_surface(l)                                      &
            =planck_flux_ground(l)-planck_flux_bottom(l)
        END DO
        IF (l_clear) THEN
          DO l=1, n_profile
            flux_direct_clear_part(l, n_layer)=0.0e+00_RealK
          END DO
        END IF

      END IF

    ELSE IF (i_angular_integration == ip_spherical_harmonic) THEN

      IF (isolir == ip_solar) THEN
        DO l=1, n_profile
          i_direct_part(l, 0)=solar_irrad(l)
          flux_inc_down(l)=0.0e+00_RealK
        END DO
      ELSE
        DO l=1, n_profile
          flux_inc_down(l)=-planck_flux_top(l)
          d_planck_flux_surface(l)                                      &
            =planck_flux_ground(l)-planck_flux_bottom(l)
        END DO
      END IF

    END IF
  
!   Set the absorption for the gas mixture
    k_gas_abs(1:n_profile,1:n_layer) =                                  &
      k_esft_layer_mix_red(1:n_profile,1:n_layer,iex)
  
! DEPENDS ON: monochromatic_radiance
    CALL monochromatic_radiance(ierr                                    &
      , control, cld, bound                                             &
!                 Atmospheric properties
      , n_profile, n_layer, d_mass                                      &
!                 Angular integration
      , i_angular_integration, i_2stream                                &
      , l_rescale, n_order_gauss                                        &
      , n_order_phase, ms_min, ms_max, i_truncation, ls_local_trunc     &
      , accuracy_adaptive, euler_factor                                 &
      , i_sph_algorithm, i_sph_mode                                     &
!                   Precalculated angular arrays
      , ia_sph_mm, cg_coeff, uplm_zero, uplm_sol                        &
!                 Treatment of scattering
      , i_scatter_method                                                &
!                 Options for solver
      , i_solver                                                        &
!                 Gaseous propreties
      , k_gas_abs                                                       &
!                 Options for equivalent extinction
      , .FALSE., dummy_ke                                               &
!                 Spectral region
      , isolir                                                          &
!                 Infra-red properties
      , diff_planck_band                                                &
      , l_ir_source_quad, diff_planck_band_2                            &
!                 Conditions at TOA
      , zen_0, flux_inc_direct, flux_inc_down                           &
      , i_direct_part                                                   &
!                 Surface properties
      , d_planck_flux_surface                                           &
      , ls_brdf_trunc, n_brdf_basis_fnc, rho_alb                        &
      , f_brdf, brdf_sol, brdf_hemi                                     &
!                 Optical properties
      , ss_prop                                                         &
!                 Cloudy properties
      , l_cloud, i_cloud                                                &
!                 Cloud geometry
      , n_cloud_top, iex                                                &
      , n_region, k_clr, i_region_cloud, frac_region                    &
      , w_free, cloud_overlap                                           &
      , n_column_slv, list_column_slv                                   &
      , i_clm_lyr_chn, i_clm_cld_typ, area_column                       &
!                   Levels for calculating radiances
      , n_viewing_level, i_rad_layer, frac_rad_layer                    &
!                   Viewing Geometry
      , n_direction, direction                                          &
!                 Calculated fluxes
      , flux_direct_part, flux_total_part                               &
!                   Calculated radiances
      , radiance_part                                                   &
!                   Calculated rate of photolysis
      , photolysis_part                                                 &
!                 Flags for clear-sky calculations
      , l_clear, i_solver_clear                                         &
!                 Clear-sky fluxes calculated
      , flux_direct_clear_part, flux_total_clear_part                   &
!                 Dimensions of arrays
      , nd_profile, nd_layer, nd_layer_clr, id_ct, nd_column            &
      , nd_flux_profile, nd_radiance_profile, nd_j_profile              &
      , nd_cloud_type, nd_region, nd_overlap_coeff                      &
      , nd_max_order, nd_sph_coeff                                      &
      , nd_brdf_basis_fnc, nd_brdf_trunc, nd_viewing_level              &
      , nd_direction, nd_source_coeff                                   &
      )

!   Increment the fluxes within the band.
    weight_incr=weight_band*w_esft_target(iex)
    IF (l_blue_flux_surf)                                               &
      weight_blue_incr=weight_blue*w_esft_target(iex)
! DEPENDS ON: augment_radiance
    CALL augment_radiance(n_profile, n_layer                            &
      , i_angular_integration, i_sph_mode                               &
      , n_viewing_level, n_direction                                    &
      , isolir, l_clear, l_initial, weight_incr                         &
      , l_blue_flux_surf, weight_blue_incr                              &
!                   Actual radiances
      , flux_direct, flux_down, flux_up                                 &
      , flux_direct_blue_surf                                           &
      , flux_down_blue_surf, flux_up_blue_surf                          &
      , i_direct, radiance, photolysis                                  &
      , flux_direct_clear, flux_down_clear, flux_up_clear               &
!                   Increments to radiances
      , flux_direct_part, flux_total_part                               &
      , i_direct_part, radiance_part, photolysis_part                   &
      , flux_direct_clear_part, flux_total_clear_part                   &
!                   Dimensions
      , nd_flux_profile, nd_radiance_profile, nd_j_profile              &
      , nd_layer, nd_viewing_level, nd_direction                        &
      )

!   Add in the increments from surface tiles
    IF (l_tile) THEN
! DEPENDS ON: augment_tiled_radiance
      CALL augment_tiled_radiance(ierr                                  &
        , n_point_tile, n_tile, list_tile                               &
        , i_angular_integration, isolir, l_initial                      &
        , weight_incr, l_blue_flux_surf, weight_blue_incr               &
!                   Surface characteristics
        , rho_alb_tile                                                  &
!                   Actual radiances
        , flux_up_tile, flux_up_blue_tile                               &
!                   Increments to radiances
        , flux_direct_part(1, n_layer)                                  &
        , flux_total_part(1, 2*n_layer+2)                               &
        , planck_flux_tile, planck_flux_bottom                          &
!                   Dimensions
        , nd_flux_profile, nd_point_tile, nd_tile                       &
        , nd_brdf_basis_fnc                                             &
        )
    END IF
    
!   After the first call to these routines quantities should be
!   incremented rather than initialized, until the flag is reset.
    l_initial=.FALSE.
    
  END DO

  IF (lhook) CALL dr_hook(RoutineName,zhook_out,zhook_handle)

END SUBROUTINE solve_band_random_overlap_resort_rebin
