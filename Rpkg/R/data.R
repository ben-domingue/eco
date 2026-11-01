#' Baird's tapir camera-trap detections, Rio Indio, Nicaragua, 2014
#'
#' The table `schank_2015_tapir_occ` as released in eco version 1, shipped so the
#' converters can be tried without a network. 22 cameras, 72 daily occasions,
#' one taxon; 1,008 rows, each a camera-day on which the camera was running.
#' Coordinates are coarsened to a 0.1-degree grid cell centre because the taxon
#' is IUCN Endangered and the deposit gave exact camera locations.
#'
#' @format `schank_2015_tapir_occ`: a data.frame with columns `unit`, `taxon`,
#'   `y`, `occasion`, `unit_trapdays`, `unit_decimalLatitude`,
#'   `unit_decimalLongitude`, `unit_coordinateUncertaintyInMeters`.
#'   `schank_2015_tapir_occ__taxa`: its taxon side table (one row).
#' @source Schank, C. (2015). Tapir detection histories (Tapirus bairdii) from
#'   Rio Indio, Nicaragua. Zenodo, CC0. \doi{10.5281/zenodo.17602}
#' @examples
#' umf <- eco_to_unmarked(schank_2015_tapir_occ)
#' if (requireNamespace("unmarked", quietly = TRUE)) unmarked::occu(~1 ~1, umf)
"schank_2015_tapir_occ"

#' @rdname schank_2015_tapir_occ
"schank_2015_tapir_occ__taxa"
