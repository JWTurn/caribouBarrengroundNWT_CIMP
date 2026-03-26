#' @title make land layer for barrenground caribou models
#' @export
#' @author Julie W. Turner

makeBarrengroundLand <- function(studyAreaLarge, inPath, dPath){
  #scanfi
  lc <- reproducible::prepInputs(url = 'https://ftp.maps.canada.ca/pub/nrcan_rncan/Forests_Foret/SCANFI/v1/SCANFI_att_nfiLandCover_SW_2020_v1.2.tif',
                                 inputsPath = inPath,
                                 destinationPath = dPath,
                                 fun = 'terra::rast',
                                 to = studyAreaLarge,
                                 method = 'near') |>
    reproducible::Cache(.functionName = 'lc')
  lc_seg <- terra::segregate(lc)
  names(lc_seg) <- paste0('LC_', names(lc_seg))

  # CanVec
  waterBodies <- reproducible::prepInputs(url = 'https://ftp.maps.canada.ca/pub/nrcan_rncan/vector/canvec/shp/Hydro/canvec_250K_NT_Hydro_shp.zip',
                                          inputsPath = inPath,
                                          destinationPath = dPath,
                                          fun = 'terra::vect',
                                          to = studyAreaLarge) |>
    reproducible::Cache(.functionName = 'wb')

  wbRast <- terra::rasterize(waterBodies, lc)
  dist_wb <- terra::mask(terra::distance(wbRast),lc)
  exp_wb <- 1- exp(-0.003*dist_wb)
  names(exp_wb) <- 'exp_wb'

  # ECCC for now
  disturbance <- prep_anthroDisturbance(inputsPath = inPath, studyArea = studyAreaLarge,
                                        dataPath = dPath, source = 'ECCC', studyAreaName = NULL)

  disturbRast <- terra::rasterize(disturbance$intYear2020$polys, lc)
  dist_ad <- terra::mask(terra::distance(disturbRast), lc)
  exp_ad <- 1- exp(-0.0002*dist_ad)
  names(exp_ad) <- 'exp_ad'

  # fires <- combine_fire_DB(nbacURL = 'https://cwfis.cfs.nrcan.gc.ca/downloads/nbac/NBAC_1972to2024_20250506_shp.zip',
  #                          nfdbURL = 'https://cwfis.cfs.nrcan.gc.ca/downloads/nfdb/fire_poly/current_version/NFDB_poly_pre1972.zip',
  #                          dPath = inPath,
  #                          studyArea = studyAreaLarge, studyAreaName = NULL, savePath = NULL) |>
  #   Cache()
  all <- c(lc_seg, exp_wb, exp_ad)
  return(all)
}
