rm(list = ls())
options(scipen = 999)


library(sf)


## ---------------------------------------------------------------------------
## 1. CONFIGURATION
## ---------------------------------------------------------------------------

CLEAN_CSV <- "PIDBA_2026_CLEAN.csv"
OUT_DIR   <- "PIDBA_2026_GIS"

OUTPUT_CRS <- 4326      # WGS84. Use "ESRI:102008" for North America Albers.

WRITE_GPKG <- TRUE      # duplicate of the layer with full-length field names

## 3,201 of the 5,897 records are zero on every map column (localities recorded
## with no diagnostic points tallied — mostly Mexico). They can never draw on
## any map, but they are kept by default so the layer stays a faithful copy of
## the database. Set TRUE to drop them and slim the attribute table.
DROP_EMPTY_RECORDS <- FALSE

## Map 3: the instructions say "Columns AE to BD, and in Columns ED, EF, and EG"
## but label it n = 9,126, which is AE:BD alone. EG is Other Fluted Untyped
## (Map 1), so this reads it as ED/EE/EF — Mesa, Sluiceway, Chindadn — and
## includes them per the Figure 3 text. Set FALSE for the AE:BD-only version.
MAP3_INCLUDE_NORTHERN <- TRUE

dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

## ---------------------------------------------------------------------------
## 2. INPUT
## ---------------------------------------------------------------------------

if (exists("pidba") && is.data.frame(pidba)) {
  message("Using the `pidba` data frame already in the environment.")
  dat <- as.data.frame(pidba)
} else {
  dat <- read.csv(CLEAN_CSV, stringsAsFactors = FALSE, check.names = FALSE,
                  encoding = "UTF-8", na.strings = c("", "NA"))
}
stopifnot(all(c("lat", "long", "COUNTY", "CODE", "SAMPLE") %in% names(dat)))

no_coords <- is.na(dat$lat) | is.na(dat$long)
if (any(no_coords)) {
  message("Dropping ", sum(no_coords), " record(s) with no coordinates.")
  dat <- dat[!no_coords, , drop = FALSE]
}

## ---------------------------------------------------------------------------
## 3. EXCEL COLUMN LETTERS
##    The mapping instructions are written in spreadsheet column letters, so the
##    definitions below are too — they can be proof-read straight against the
##    Word document without translating anything.
## ---------------------------------------------------------------------------

XL_ORDER <- c(
  "Country","CODE","STAB","INDEX","COUNTY","lat","long","FPS","Area_SQ_KM","SAMPLE",
  "CLOVIS","ROSS_COUNTY","CLOVIS_VARIANT","WAISTED_FLUTED","FISHTAIL","FOLSOM",
  "MIDLAND","REDSTONE","CUMBERLAND","GAINEY","WHEELER","PELICAN","WEST_ATHENS_HILL",
  "BULL_BROOK","Vail_DEBERT","BARNES","NORTHUMBERLAND","MICHAUD_NEPONSET","CROWFIELD",
  "HOLCOMB_NICOLAS","SUWANNEE","SIMPSON","BEAVER_LAKE","QUAD","COLDWATER","HINDS",
  "ARKABUTLA","GOSHEN","AGATE_BASIN","HELL_GAP","WILSON","ANGOSTURA","SCOTTSBLUFF",
  "MILNESAND","ALBERTA","BROWNS_VALLEY","JIMMY_ALLEN_FREDERICK","EDEN","CODY",
  "CODY_KNIFE","PLAINVIEW","PACKARD","PRYOR_STEMMED","LOVELL_CONSTRICTED",
  "UNFLUTED_LANCEOLATE","STE_ANNE_VARNEY","HAW_RIVER","HI_LO","GOLONDRINA",
  "HARPETH_RIVER","MESERVE","DALTON","BASALLY_THINNED_DALTON","LANCEOLATE_DALTON",
  "SIDE_NOTCHED_DALTON","GREENBRIER_DALTON","NUCKOLLS_DALTON","HARDAWAY_DALTON",
  "HARDAWAY_BLADE","SAN_PATRICE_var._Hope","SAN_PATRICE_var._St._Johns",
  "SAN_PATRICE_var._Brazos","SAN_PATRICE_var._Kisatchie","SAN_PATRICE_var._Dixon",
  "HARDAWAY_SIDE_NOTCHED","BOLEN_SIDE_NOTCHED","UNTYPED_AND_TAYLOR_SIDE_NOTCHED",
  "SANTA_FE","CACHE_RIVER","BIG_SANDY","BRECKENRiDGE","UNION","CHIPOLA",
  "SAN_PATRICE_no_var.","GILCREST","FAIRLAND","SAN_PATRICE_var._Keithville",
  "SAN_PATRICE_var._Leaf_River","SAN_PATRICE_var._GENEILL","PALMER_CORNER_NOTCHED",
  "STILLWELL","DECATUR","LOST_LAKE","PINE_TREE","THEBES",
  "UNTYPED_AND_KIRK_CORNER_NOTCHED","DOVETAIL_ST._CHARLES","RICE_LOBED","HARDIN",
  "JUDE_CAVE_SPRING","KANAWHA","MACCORKLE","LECROY","ST._ALBANS","BIFURCATE",
  "KIRK_SERRATED","KIRK_STEMMED","TAAN","XIL","XILJU","CI_AMOL","CI_BARBED",
  "COOPERS_FERRY","HASKETT","COUGER_MTN","WINDUST","CASCADE","PARMAN","LIND_COULEE",
  "LAKE_MOHAVE","BONNEVILLE","SILVER_LAKE_","STUBBY","GBSS_GENERALIZED_WST",
  "CRESCENT","EDGEFIELD_SCRAPER","END_SCRAPER","CFG_ADZE","LIMACES",
  "PRISMATIC_BLADES_CORES","PIECES_ESQUILLEES","GROUNDSTONE_GROOVED_ABRADERS",
  "BONE_IVORY_POINTS_RODS","MESA","SLUICEWAY","CHINDADN","OTHER_FLUTED_UNTYPED",
  "NON_CLOVIS_FLUTED_TYPES","NON_FLUTED_VARIETIES","CLOVIS_FORMS",
  "FOLSOM_per_1000_sq_km","CUMBERLAND_per_1000_sq_km","SUWANEE_per_1000_sq_km",
  "SIMPSON_per_1000_sq_km","SUWANEE_SIMPSON_per_1000_sq_km","SAMPLE_per_1000_sq_km",
  "REFERENCES")

xl_num <- function(letters_)
  vapply(toupper(letters_), function(L)
    Reduce(function(a, b) a * 26L + b, utf8ToInt(L) - 64L), integer(1),
    USE.NAMES = FALSE)

XL <- function(from, to = NULL) {
  i <- xl_num(from); j <- if (is.null(to)) i else xl_num(to)
  nm <- XL_ORDER[i:j]
  miss <- setdiff(nm, names(dat))
  if (length(miss)) stop("Column(s) not in the cleaned data: ",
                         paste(miss, collapse = ", "), call. = FALSE)
  nm
}

xl_letter <- function(i) {
  out <- character(0)
  while (i > 0) { r <- (i - 1L) %% 26L; out <- c(LETTERS[r + 1L], out)
  i <- (i - 1L) %/% 26L }
  paste(out, collapse = "")
}

## ---------------------------------------------------------------------------
## 4. MAP COLUMN DEFINITIONS
##    full  : Map code + description. The text before the first underscore
##            becomes the .shp field name (Map2c); the whole string is the
##            .gpkg field name (Map2c_Cumberland).
##    cols  : the workbook columns summed into it
##
##    Every distribution the instructions ask to be drawn separately gets its
##    own column — including the individual types inside the "minor types" and
##    "separate coloured dots" maps, so each can be symbolised on its own.
## ---------------------------------------------------------------------------

## The DBF field name is the map code — the part of the full name before the
## first underscore. Map1_Clovis_Untyped_Fluted -> field "Map1".
M <- function(full, cols, n_doc = NA_real_)
  list(short = sub("_.*$", "", full), full = full, cols = cols, n_doc = n_doc)

map_cols <- list(
  
  ## ---- Map 1. Clovis and Untyped Fluted ----------------------------------
  M("Map1_Clovis_Untyped_Fluted",                      c(XL("EJ"), XL("EG")), 16317),
  M("Map1a_Clovis_Forms",                              XL("EJ"),               8817),
  M("Map1b_Other_Fluted_Untyped",                      XL("EG"),               7500),
  
  ## ---- Map 2. Non-Clovis Fluted Point Types ------------------------------
  M("Map2_Non_Clovis_Fluted",                          XL("N", "AD"),          9008),
  M("Map2a_Folsom_Midland",                            XL("P", "Q"),           5377),
  M("Map2a1_Folsom",                                   XL("P"),                4661),
  M("Map2a2_Midland",                                  XL("Q"),                 716),
  M("Map2b_Redstone",                                  XL("R"),                 440),
  M("Map2c_Cumberland",                                XL("S"),                 916),
  M("Map2d_Gainey",                                    XL("T"),                 466),
  M("Map2Minor_Other_Minor_Fluted",
    c(XL("N", "O"), XL("U", "AD")),                                           1732),
  M("Map2e_Michaud_Neponset",                          XL("AB"),                421),
  M("Map2f_Holcombe_Nicholas",                         XL("AD"),                368),
  M("Map2g_Minor_Non_Clovis_Fluted",
    c(XL("Z"), XL("AC"), XL("V"), XL("Y"), XL("W", "X"), XL("U"), XL("AA"),
      XL("N"), XL("O")),                                                       943),
  M("Map2g1_Barnes",                                   XL("Z"),                 192),
  M("Map2g2_Crowfield",                                XL("AC"),                160),
  M("Map2g3_Pelican",                                  XL("V"),                 146),
  M("Map2g4_Vail_Debert",                              XL("Y"),                 120),
  M("Map2g5_West_Athens_Hill_Bull_Brook",XL("W", "X"),            116),
  M("Map2g6_Wheeler",                                  XL("U"),                  72),
  M("Map2g7_Northumberland",                           XL("AA"),                 54),
  M("Map2g8_Waisted_Fluted",                           XL("N"),                  45),
  M("Map2g9_Fish_Tail",                                XL("O"),                  38),
  
  ## ---- Map 3. Unfluted Presumed Post-Clovis Lanceolate Forms -------------
  M("Map3_Unfluted_Lanceolate_Forms",
    if (MAP3_INCLUDE_NORTHERN) c(XL("AE", "BD"), XL("ED", "EF")) else XL("AE", "BD"),
    if (MAP3_INCLUDE_NORTHERN) 9574 else 9126),
  M("Map3a_Unfluted_Lanceolate",                       XL("BC"),               1129),
  M("Map3b_Agate_Basin",                               XL("AM"),               1082),
  M("Map3c_Plainview",                                 XL("AY"),                812),
  M("Map3d_Cody_And_Cody_Knife",                       XL("AW", "AX"),          763),
  M("Map3d1_Cody",                                     XL("AW"),                643),
  M("Map3d2_Cody_Knife",                               XL("AX"),                120),
  M("Map3e_Angostura",                                 XL("AP"),                427),
  M("Map3f_Jimmy_Allen_Frederick",                     XL("AU"),                421),
  M("Map3g_Scottsbluff",                               XL("AQ"),                363),
  M("Map3h_Hell_Gap",                                  XL("AN"),                316),
  M("Map3i_Minor_Western_Lanceolate",
    c(XL("AV"), XL("AR"), XL("AS"), XL("AL"), XL("BA"), XL("AO"),
      XL("ED"), XL("EE"), XL("EF")),                                          1250),
  M("Map3i1_Eden",                                     XL("AV"),                255),
  M("Map3i2_Milnesand",                                XL("AR"),                143),
  M("Map3i3_Alberta",                                  XL("AS"),                128),
  M("Map3i4_Goshen",                                   XL("AL"),                117),
  M("Map3i5_Pryor_Stemmed",                            XL("BA"),                 85),
  M("Map3i6_Wilson",                                   XL("AO"),                 74),
  M("Map3i7_Mesa",                                     XL("ED"),                157),
  M("Map3i8_Sluiceway",                                XL("EE"),                213),
  M("Map3i9_Chindadn",                                 XL("EF"),                 78),
  M("Map3j_Suwannee",                                  XL("AE"),                723),
  M("Map3k_Simpson",                                   XL("AF"),                492),
  M("Map3l_Beaver_Lake",                               XL("AG"),                715),
  M("Map3m_Quad",                                      XL("AH"),                702),
  M("Map3n_Ste_Anne_Varney",                           XL("BD"),                131),
  M("Map3o_Minor_Eastern_Lanceolate",                  XL("AI", "AK"),          203),
  M("Map3o1_Coldwater",                                XL("AI"),                124),
  M("Map3o2_Hinds",                                    XL("AJ"),                 70),
  M("Map3o3_Arkabutla",                                XL("AK"),                  9),
  
  ## ---- Map 4. Western Stemmed --------------------------------------------
  M("Map4_Western_Stemmed",                            XL("DD", "DT"),         4832),
  M("Map4a_Coastal_Western_Stemmed",                   XL("DD", "DH"),          122),
  M("Map4a1_Taan",                                     XL("DD"),                  3),
  M("Map4a2_Xil",                                      XL("DE"),                 15),
  M("Map4a3_Xilju",                                    XL("DF"),                  4),
  M("Map4a4_CI_Amol",                                  XL("DG"),                  3),
  M("Map4a5_CI_Barbed",                                XL("DH"),                 97),
  M("Map4b_Generalized_Western_Stemmed",               XL("DT"),               1482),
  M("Map4c_Lake_Mohave",                               XL("DP"),                650),
  M("Map4d_Silver_Lake",                               XL("DR"),                511),
  M("Map4e_Windust",                                   XL("DL"),                529),
  M("Map4f_Bonneville",                                XL("DQ"),                389),
  M("Map4g_Parman",                                    XL("DN"),                360),
  M("Map4h_Cascade",                                   XL("DM"),                289),
  M("Map4i_Haskett",                                   XL("DJ"),                194),
  M("Map4j_Cougar_Mountain",                           XL("DK"),                181),
  M("Map4k_Stubby",                                    XL("DS"),                115),
  
  ## ---- Map 5. Dalton and related forms -----------------------------------
  M("Map5_Dalton_And_Related",                         XL("BF", "BU"),         9612),
  M("Map5a_Hi_Lo",                                     XL("BF"),                524),
  M("Map5b_Golondrina",                                XL("BG"),                154),
  M("Map5c_Meserve",                                   XL("BI"),                 81),
  M("Map5d_Dalton_Variants",                           c(XL("BH"), XL("BJ", "BO")), 7765),
  M("Map5d1_Harpeth_River",                            XL("BH"),                117),
  M("Map5d2_Greenbrier_Dalton",                        XL("BN"),               1489),
  M("Map5d3_Dalton",                                   XL("BJ"),               4948),
  M("Map5d4_Basally_Thinned_Dalton",                   XL("BK"),                598),
  M("Map5d5_Lanceolate_Dalton",                        XL("BL"),                343),
  M("Map5d6_Side_Notched_Dalton",                      XL("BM"),                263),
  M("Map5d7_Nuckolls_Dalton",                          XL("BO"),                  7),
  M("Map5e_Hardaway_Dalton_And_Blade",                 XL("BP", "BQ"),          392),
  M("Map5e1_Hardaway_Dalton",                          XL("BP"),                338),
  M("Map5e2_Hardaway_Blade",                           XL("BQ"),                 54),
  M("Map5f_Hardaway_Dalton_Blade_Side_Notched",
    c(XL("BP", "BQ"), XL("BW")),                                               578),
  M("Map5f1_Hardaway_Side_Notched",                    XL("BW"),                186),
  M("Map5g_San_Patrice_Dalton_Like",                   XL("BR", "BU"),          696),
  M("Map5g1_San_Patrice_var_Hope",                     XL("BR"),                212),
  M("Map5g2_San_Patrice_var_St_Johns",                 XL("BS"),                392),
  M("Map5g3_San_Patrice_var_Brazos",                   XL("BT"),                 19),
  M("Map5g4_San_Patrice_var_Kisatchie",                XL("BU"),                 73),
  
  ## ---- Map 6. Early Holocene notched / bifurcate / stemmed ---------------
  M("Map6_Early_Holocene_Notched_Bifurcate_Stemmed",
    XL("BV", "DC"),                                                          29831),
  M("Map6a_Side_Notched",                              XL("BV", "CE"),         5439),
  M("Map6b_Corner_Notched",                            XL("CG", "CV"),        18309),
  M("Map6c_Bifurcate",                                 XL("CW", "DA"),         4798),
  M("Map6d_Kirk_Serrated",                             XL("DB"),                265),
  M("Map6e_Kirk_Stemmed",                              XL("DC"),                503),
  M("Map6f_San_Patrice_No_Variety",                    XL("CF"),                517),
  
  ## ---- Map 7. Unusual Tool Forms -----------------------------------------
  M("Map7_Unusual_Tool_Forms",                         XL("DU", "EC"),        24513),
  M("Map7a_Crescents",                                 XL("DU"),               2804),
  M("Map7b_Hafted_Knives",                             XL("DV"),                220),
  M("Map7c_End_Scrapers",                              XL("DW"),              12750),
  M("Map7d_Adzes",                                     XL("DX"),                870),
  M("Map7e_Limaces",                                   XL("DY"),                155),
  M("Map7f_Prismatic_Blades_Cores",                    XL("DZ"),               4609),
  M("Map7g_Pieces_Esquillees",                         XL("EA"),               2499),
  M("Map7h_Groundstone_Abraders",                      XL("EB"),                311),
  M("Map7i_Bone_Ivory_Tools",                          XL("EC"),                295)
)

## ---- integrity checks ------------------------------------------------------
short_names <- vapply(map_cols, `[[`, "", "short")
full_names  <- vapply(map_cols, `[[`, "", "full")
if (any(nchar(short_names) > 10))
  stop("Map code(s) over the 10-character DBF limit: ",
       paste(short_names[nchar(short_names) > 10], collapse = ", "), call. = FALSE)
if (anyDuplicated(short_names))
  stop("Duplicate map code(s): ",
       paste(unique(short_names[duplicated(short_names)]), collapse = ", "), call. = FALSE)
if (anyDuplicated(full_names))
  stop("Duplicate full field name(s).", call. = FALSE)

## ---- coverage check --------------------------------------------------------
## Workbook count columns are CLOVIS (K) .. OTHER FLUTED UNTYPED (EG). Report
## any that no map draws, so nothing is silently left off the figures.
TYPE_COLS <- XL_ORDER[11:137]
used_cols <- unique(unlist(lapply(map_cols, `[[`, "cols")))
## CLOVIS_FORMS (EJ) is the roll-up of K:M, so credit its parts as covered
if ("CLOVIS_FORMS" %in% used_cols) used_cols <- c(used_cols, XL_ORDER[11:13])
uncovered <- setdiff(TYPE_COLS, used_cols)

## ---------------------------------------------------------------------------
## 5. BUILD THE LAYER
## ---------------------------------------------------------------------------

ID_FIELDS <- intersect(
  c("xl_row", "Country", "CODE", "ADMIN_UNIT", "REGION", "COUNTY",
    "lat", "long", "Area_SQ_KM", "SAMPLE"), names(dat))

out <- dat[, ID_FIELDS, drop = FALSE]
names(out)[names(out) == "ADMIN_UNIT"] <- "ADMIN"
names(out)[names(out) == "Area_SQ_KM"] <- "AREA_SQKM"

row_total <- function(cols) {
  m <- as.matrix(dat[, cols, drop = FALSE]); storage.mode(m) <- "double"
  as.integer(rowSums(m, na.rm = TRUE))
}

for (m in map_cols) out[[m$short]] <- row_total(m$cols)

all_zero <- rowSums(as.matrix(out[, short_names, drop = FALSE])) == 0
if (DROP_EMPTY_RECORDS) {
  message("Dropping ", sum(all_zero), " record(s) that are zero on every map column.")
  out <- out[!all_zero, , drop = FALSE]
}

to_sf <- function(df) {
  g <- st_as_sf(df, coords = c("long", "lat"), crs = 4326, remove = FALSE)
  if (!identical(OUTPUT_CRS, 4326)) g <- st_transform(g, OUTPUT_CRS)
  g
}

layer <- to_sf(out)

suppressWarnings(st_write(layer, file.path(OUT_DIR, "PIDBA_2026_maps.shp"),
                          delete_dsn = TRUE, quiet = TRUE,
                          layer_options = "ENCODING=UTF-8"))

if (WRITE_GPKG) {
  gpkg <- layer
  names(gpkg)[match(short_names, names(gpkg))] <- full_names
  suppressWarnings(st_write(gpkg, file.path(OUT_DIR, "PIDBA_2026_maps.gpkg"),
                            layer = "PIDBA_2026_maps", delete_dsn = TRUE, quiet = TRUE))
}

## ---------------------------------------------------------------------------
## 6. CROSSWALK
## ---------------------------------------------------------------------------

col_rows <- list()

for (m in map_cols) {
  v <- out[[m$short]]
  col_rows[[length(col_rows) + 1L]] <- data.frame(
    map_code     = m$short,
    map          = m$full,
    columns_xl   = paste(vapply(sort(match(m$cols, XL_ORDER)), xl_letter, ""),
                         collapse = ", "),
    columns_r    = paste(m$cols, collapse = ", "),
    total        = sum(v),
    n_instructions = m$n_doc,
    difference   = sum(v) - m$n_doc,
    n_counties   = sum(v > 0),
    max_count    = max(v),
    qgis_filter  = paste0('"', m$short, '" > 0'),
    arcgis_where = paste0(m$short, ' > 0'),
    stringsAsFactors = FALSE)
}

map_columns <- do.call(rbind, col_rows)
write.csv(map_columns, file.path(OUT_DIR, "PIDBA_map_columns.csv"), row.names = FALSE)

## ---------------------------------------------------------------------------
## 7. REPORT
## ---------------------------------------------------------------------------

hr <- function() cat(strrep("-", 78), "\n")
cat("\nPIDBA 2026 — SINGLE-LAYER GIS EXPORT\n"); hr()
cat("Output directory :", normalizePath(OUT_DIR), "\n")
cat("Layer            : PIDBA_2026_maps.shp",
    if (WRITE_GPKG) "(+ .gpkg with full field names)" else "", "\n")
cat("Records          :", nrow(out),
    if (!DROP_EMPTY_RECORDS) paste0(" (", sum(all_zero),
                                    " are zero on every map column - set DROP_EMPTY_RECORDS to drop them)")
    else "", "\n")
cat("Map columns      :", length(map_cols),
    "  (plus", length(ID_FIELDS) - 2, "identity fields)\n")
cat("CRS              :", as.character(OUTPUT_CRS), "\n")
cat("Values           : raw counts, unclassified\n")
hr()
disagree <- map_columns[!is.na(map_columns$difference) & map_columns$difference != 0,
                        c("map_code", "map", "total", "n_instructions", "difference")]
cat("COLUMNS WHOSE TOTAL DIFFERS FROM THE COUNT IN THE INSTRUCTIONS:",
    nrow(disagree), "of", nrow(map_columns), "\n")
if (nrow(disagree)) print(disagree, row.names = FALSE)
cat("WORKBOOK COUNT COLUMNS DRAWN BY NO MAP:", length(uncovered), "\n")
if (length(uncovered))
  for (u in uncovered)
    cat("   ", xl_letter(match(u, XL_ORDER)), " ", u, " (n = ",
        format(sum(dat[[u]], na.rm = TRUE), big.mark = ","), ")\n", sep = "")
hr()
cat("To draw a map: filter the layer to exclude zeros, then symbolise on that\n")
cat("column. Both filter strings are in PIDBA_map_columns.csv, e.g.\n")
cat('   QGIS        "Map1" > 0\n')
cat("   ArcGIS Pro   Map1 > 0\n")
cat("PIDBA_map_columns.csv also carries each column's total and highest single\n")
cat("count, for setting class ranges by hand.\n")
hr()