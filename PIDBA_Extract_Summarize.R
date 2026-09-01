rm(list = ls())
options(scipen = 999)

library(readxl)
library(dplyr)
library(tidyr)



## ---------------------------------------------------------------------------
## 1. CONFIGURATION
## ---------------------------------------------------------------------------


PIDBA_FILE  <- "/Users/darcymiller/Library/CloudStorage/Dropbox/Paleo_Odyssey 26/Anderson/Round 3/PIDBA Locational Database 26 August 2026 Final.xlsx"
PIDBA_SHEET <- "PALEO POINT WORKING DATABASE"

HDR_ROW_TOP <- 12L     # first header line
HDR_ROW_BOT <- 13L     # second header line
DATA_FIRST  <- 14L     # first record
DATA_LAST   <- 5906L   # last record
TOTALS_ROW  <- 5907L   # spreadsheet GRAND TOTALS row

N_COL <- 141L          # columns A .. EK

## Blank count cells are treated as zero (the spreadsheet convention: a blank
## type cell means "none reported"). Set FALSE to keep them as NA.
COUNTS_NA_TO_ZERO <- TRUE

## Latitude/longitude pairs that are obviously transposed (|lat| > 90 while
## |long| <= 90) are swapped back. Set FALSE to leave them alone and only report.
FIX_SWAPPED_COORDS <- TRUE

## Recompute the spreadsheet's derived columns (SAMPLE, CLOVIS_FORMS,
## NON_CLOVIS_FLUTED_TYPES, NON_FLUTED_VARIETIES) from the raw type columns
## rather than trusting the cached formula values.
RECOMPUTE_DERIVED <- TRUE

## Area is recorded in SQUARE MILES in this version of the workbook. The
## per-1000-sq-km rates that earlier versions carried as columns are rebuilt
## here from the converted area.
SQ_MI_TO_SQ_KM <- 2.589988110336




## ---------------------------------------------------------------------------
## 2. COLUMN NAMES
##    Keys are the two header lines (rows 12 and 13) squished into one string.
## ---------------------------------------------------------------------------

pidba_name_map <- c(
  "Country"                                                  = "Country",
  "CODE"                                                     = "CODE",
  "STAB"                                                     = "STAB",
  "INDEX"                                                    = "INDEX",
  "COUNTY"                                                   = "COUNTY",
  "lat"                                                      = "lat",
  "long"                                                     = "long",
  "FIPS"                                                     = "FIPS",
  "Area SQ MI"                                               = "Area_SQ_MI",
  "SAMPLE"                                                   = "SAMPLE",
  "CLOVIS"                                                   = "CLOVIS",
  "ROSS COUNTY"                                              = "ROSS_COUNTY",
  "CLOVIS VARIANT"                                           = "CLOVIS_VARIANT",
  "WAISTED FLUTED"                                           = "WAISTED_FLUTED",
  "FISH TAIL"                                                = "FISHTAIL",
  "FOLSOM"                                                   = "FOLSOM",
  "MIDLAND"                                                  = "MIDLAND",
  "REDSTONE"                                                 = "REDSTONE",
  "CUMBERLAND"                                               = "CUMBERLAND",
  "WHIPPLE/ GAINEY"                                          = "GAINEY",
  "WHEELER"                                                  = "WHEELER",
  "PELICAN"                                                  = "PELICAN",
  "WEST ATHENS HILL"                                         = "WEST_ATHENS_HILL",
  "BULL BROOK"                                               = "BULL_BROOK",
  "VAIL DEBERT"                                              = "Vail_DEBERT",
  "BARNES"                                                   = "BARNES",
  "NORTHUMBERLAND"                                           = "NORTHUMBERLAND",
  "MICHAUD NEPONSET"                                         = "MICHAUD_NEPONSET",
  "CROWFIELD"                                                = "CROWFIELD",
  "HOLCOMBE NICOLAS"                                         = "HOLCOMB_NICOLAS",
  "SUWANNEE"                                                 = "SUWANNEE",
  "SIMPSON"                                                  = "SIMPSON",
  "BEAVER LAKE"                                              = "BEAVER_LAKE",
  "QUAD"                                                     = "QUAD",
  "COLDWATER"                                                = "COLDWATER",
  "HINDS"                                                    = "HINDS",
  "ARKABUTLA"                                                = "ARKABUTLA",
  "GOSHEN"                                                   = "GOSHEN",
  "AGATE BASIN"                                              = "AGATE_BASIN",
  "HELL GAP"                                                 = "HELL_GAP",
  "WILSON"                                                   = "WILSON",
  "ANGOSTURA"                                                = "ANGOSTURA",
  "SCOTTSBLUFF"                                              = "SCOTTSBLUFF",
  "MILNESAND"                                                = "MILNESAND",
  "ALBERTA"                                                  = "ALBERTA",
  "BROWNS VALLEY"                                            = "BROWNS_VALLEY",
  "JIMMY ALLEN/ FREDERICK"                                   = "JIMMY_ALLEN_FREDERICK",
  "EDEN"                                                     = "EDEN",
  "CODY"                                                     = "CODY",
  "CODY KNIFE"                                               = "CODY_KNIFE",
  "PLAIN VIEW"                                               = "PLAINVIEW",
  "PACKARD"                                                  = "PACKARD",
  "PRYOR STEMMED"                                            = "PRYOR_STEMMED",
  "LOVELL CONSTRICTED"                                       = "LOVELL_CONSTRICTED",
  "UNFLUTED LANCEOLATE"                                      = "UNFLUTED_LANCEOLATE",
  "STE. ANNE VARNEY"                                         = "STE_ANNE_VARNEY",
  "MILLER, EARLY TRIANGULAR, HAW RIVER"                      = "HAW_RIVER",
  "HI-LO"                                                    = "HI_LO",
  "GOLONDRINA"                                               = "GOLONDRINA",
  "HARPETH RIVER"                                            = "HARPETH_RIVER",
  "MESERVE"                                                  = "MESERVE",
  "DALTON"                                                   = "DALTON",
  "BASALLY THINNED DALTON"                                   = "BASALLY_THINNED_DALTON",
  "LANCEOLATE DALTON"                                        = "LANCEOLATE_DALTON",
  "SIDE-NOTCHED DALTON"                                      = "SIDE_NOTCHED_DALTON",
  "GREENBRIER DALTON,"                                       = "GREENBRIER_DALTON",
  "NUCKOLLS DALTON"                                          = "NUCKOLLS_DALTON",
  "HARDAWAY DALTON"                                          = "HARDAWAY_DALTON",
  "HARDAWAY BLADE"                                           = "HARDAWAY_BLADE",
  "SAN PATRICE var. Hope"                                    = "SAN_PATRICE_var._Hope",
  "SAN PATRICE var. St. Johns"                               = "SAN_PATRICE_var._St._Johns",
  "SAN PATRICE var. Brazos"                                  = "SAN_PATRICE_var._Brazos",
  "SAN PATRICE var. Kisatchie"                               = "SAN_PATRICE_var._Kisatchie",
  "SAN PATRICE var. Dixon"                                   = "SAN_PATRICE_var._Dixon",
  "HARDAWAY SIDE NOTCHED"                                    = "HARDAWAY_SIDE_NOTCHED",
  "BOLEN SIDE NOTCHED"                                       = "BOLEN_SIDE_NOTCHED",
  "MISC UNTYPED (e.g., TAYLOR, NORTHERN) SIDE NOTCHED"       = "UNTYPED_AND_TAYLOR_SIDE_NOTCHED",
  "SANTA FE"                                                 = "SANTA_FE",
  "sn CACHE RIVER"                                           = "CACHE_RIVER",
  "sn BIG SANDY"                                             = "BIG_SANDY",
  "sn Breckenridge"                                          = "BRECKENRiDGE",
  "sn UNION"                                                 = "UNION",
  "sn CHIPOLA"                                               = "CHIPOLA",
  "SAN PATRICE no var."                                      = "SAN_PATRICE_no_var.",
  "escn GILCREST"                                            = "GILCREST",
  "escn FAIRLAND"                                            = "FAIRLAND",
  "SAN PATRICE var. Keithville"                              = "SAN_PATRICE_var._Keithville",
  "SAN PATRICE var. Leaf River"                              = "SAN_PATRICE_var._Leaf_River",
  "SAN PATRICE var. GENEILL"                                 = "SAN_PATRICE_var._GENEILL",
  "PALMER CORNER NOTCHED"                                    = "PALMER_CORNER_NOTCHED",
  "cn STILLWELL"                                             = "STILLWELL",
  "cn DECATUR"                                               = "DECATUR",
  "cn LOST LAKE"                                             = "LOST_LAKE",
  "cn PINE TREE"                                             = "PINE_TREE",
  "THEBES"                                                   = "THEBES",
  "MSC CN AND KIRK CORNER NOTCHED"                           = "UNTYPED_AND_KIRK_CORNER_NOTCHED",
  "DOVETAIL ST. CHARLES"                                     = "DOVETAIL_ST._CHARLES",
  "RICE LOBED"                                               = "RICE_LOBED",
  "HARDIN"                                                   = "HARDIN",
  "JUDE/CAVE SPRING"                                         = "JUDE_CAVE_SPRING",
  "KANAWHA"                                                  = "KANAWHA",
  "MACCORKLE"                                                = "MACCORKLE",
  "LECROY"                                                   = "LECROY",
  "ST. ALBANS"                                               = "ST._ALBANS",
  "BIFURCATE"                                                = "BIFURCATE",
  "KIRK SERRATED"                                            = "KIRK_SERRATED",
  "KIRK STEMMED"                                             = "KIRK_STEMMED",
  "TAAN"                                                     = "TAAN",
  "XIL"                                                      = "XIL",
  "XILJU"                                                    = "XILJU",
  "CI AMOL"                                                  = "CI_AMOL",
  "CI BARBED"                                                = "CI_BARBED",
  "COOPER'S FERRY"                                           = "COOPERS_FERRY",
  "HASKETT"                                                  = "HASKETT",
  "COUGAR MTN"                                               = "COUGAR_MTN",
  "WINDUST"                                                  = "WINDUST",
  "CASCADE"                                                  = "CASCADE",
  "PARMAN"                                                   = "PARMAN",
  "LIND COULEE"                                              = "LIND_COULEE",
  "LAKE MOHAVE"                                              = "LAKE_MOHAVE",
  "BONNEVILLE"                                               = "BONNEVILLE",
  "SILVER LAKE"                                              = "SILVER_LAKE_",
  "STUBBY"                                                   = "STUBBY",
  "GENERALIZED WST"                                          = "GBSS_GENERALIZED_WST",
  "CRESCENT"                                                 = "CRESCENT",
  "EDGEFIELD SCRAPER"                                        = "EDGEFIELD_SCRAPER",
  "END SCRAPER"                                              = "END_SCRAPER",
  "CLEAR FORK, GUADALUPE ADZE"                               = "CFG_ADZE",
  "LIMACES"                                                  = "LIMACES",
  "PRISMATIC BLADES/CORES"                                   = "PRISMATIC_BLADES_CORES",
  "PIECES ESQUILLEES"                                        = "PIECES_ESQUILLEES",
  "GROOVED ABRADERS GROUNDSTONE"                             = "GROUNDSTONE_GROOVED_ABRADERS",
  "BONE /IVORY POINTS, RODS, ETC."                           = "BONE_IVORY_POINTS_RODS",
  "MESA"                                                     = "MESA",
  "SLUICEWAY"                                                = "SLUICEWAY",
  "CHINDADN"                                                 = "CHINDADN",
  "OTHER FLUTED UNTYPED"                                     = "OTHER_FLUTED_UNTYPED",
  "NON CLOVIS FLUTED TYPES"                                  = "NON_CLOVIS_FLUTED_TYPES",
  "NONFLUTED POINTS AND TOOLS"                               = "NON_FLUTED_VARIETIES",
  "CLOVIS FORMS"                                             = "CLOVIS_FORMS",
  "REFERENCES"                                               = "REFERENCES"
)

## Rates are no longer columns in the workbook; they are derived below.
RATE_COLS <- c("FOLSOM_per_1000_sq_km", "CUMBERLAND_per_1000_sq_km",
               "SUWANEE_per_1000_sq_km", "SIMPSON_per_1000_sq_km",
               "SUWANEE_SIMPSON_per_1000_sq_km", "SAMPLE_per_1000_sq_km")



## ---------------------------------------------------------------------------
## 3. HELPERS
## ---------------------------------------------------------------------------

squish <- function(x) gsub("^\\s+|\\s+$", "", gsub("\\s+", " ", ifelse(is.na(x), "", x)))

## Header text is matched on an ASCII-folded key, so accented and apostrophised
## headers (PIECES ESQUILLEES (PI\u00c8CES ESQUILL\u00c9ES in the file), COOPER'S FERRY) match whatever encoding/locale R
## happens to read the workbook in. Explicit \u escapes keep this source ASCII
## and make it locale-independent (iconv //TRANSLIT is not).
deaccent <- local({
  from <- c("\u00c0","\u00c1","\u00c2","\u00c3","\u00c4","\u00c5","\u00c7",
            "\u00c8","\u00c9","\u00ca","\u00cb","\u00cc","\u00cd","\u00ce",
            "\u00cf","\u00d1","\u00d2","\u00d3","\u00d4","\u00d5","\u00d6",
            "\u00d9","\u00da","\u00db","\u00dc","\u00dd",
            "\u00e0","\u00e1","\u00e2","\u00e3","\u00e4","\u00e5","\u00e7",
            "\u00e8","\u00e9","\u00ea","\u00eb","\u00ec","\u00ed","\u00ee",
            "\u00ef","\u00f1","\u00f2","\u00f3","\u00f4","\u00f5","\u00f6",
            "\u00f9","\u00fa","\u00fb","\u00fc","\u00fd","\u00ff",
            "\u2018","\u2019","\u201c","\u201d","\u00b4","`","'","\"")
  to   <- c(rep("A", 6), "C", rep("E", 4), rep("I", 4), "N", rep("O", 5),
            rep("U", 4), "Y",
            rep("a", 6), "c", rep("e", 4), rep("i", 4), "n", rep("o", 5),
            rep("u", 4), "y", "y",
            rep("", 8))
  function(x) {
    x <- as.character(x)
    for (i in seq_along(from)) x <- gsub(from[i], to[i], x, fixed = TRUE)
    x
  }
})

## Excel error literals and other non-values that must become NA
NA_LITERALS <- c("", "`", "-", "--", "n/a", "N/A", "NA", "na", "?",
                 "#DIV/0!", "#VALUE!", "#REF!", "#NAME?", "#NULL!", "#NUM!", "#N/A")

##  Numeric coercion that survives PIDBA's text quirks:
##    "`16"      -> 16      (leading Excel text-prefix apostrophe/backtick)
##    " -111,83" -> -111.83 (comma used as decimal separator)
##    "#DIV/0!"  -> NA
##    "1,234"    -> 1234    (thousands separator)
as_pidba_numeric <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  x <- squish(as.character(x))
  x[x %in% NA_LITERALS] <- NA_character_
  x <- gsub("^[`'\u2018\u2019]+", "", x)                  # text-prefix marks
  x <- gsub("[ \\s]", "", x, perl = TRUE)                 # stray spaces
  # comma as decimal separator (e.g. "-111,83") vs thousands separator ("1,234")
  dec <- grepl("^-?\\d+,\\d{1,2}$", x)
  x[dec]  <- sub(",", ".", x[dec], fixed = TRUE)
  x[!dec] <- gsub(",", "", x[!dec], fixed = TRUE)
  suppressWarnings(as.numeric(x))
}

as_pidba_character <- function(x) {
  x <- squish(as.character(x))
  x[x %in% c("", "`")] <- NA_character_
  x
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a




## ---------------------------------------------------------------------------
## 4. READ
##    Everything is read as text and coerced deliberately — the count columns
##    can contain text-prefixed values that would otherwise be lost.
## ---------------------------------------------------------------------------

## cell_limits() anchors the block at column A. cell_rows() would silently drop
## leading all-blank columns (the GRAND TOTALS row is empty in A:F), which
## shifts every column name by six.
read_block <- function(rows, n = N_COL) {
  read_excel(
    PIDBA_FILE, sheet = PIDBA_SHEET,
    range = cell_limits(c(rows[1], 1L), c(rows[2], n)),
    col_names = FALSE, col_types = "text", .name_repair = "minimal"
  )
}

hdr <- read_block(c(HDR_ROW_TOP, HDR_ROW_BOT))
stopifnot(nrow(hdr) == 2L)
if (ncol(hdr) < N_COL) hdr[, (ncol(hdr) + 1L):N_COL] <- NA_character_
hdr <- hdr[, seq_len(N_COL), drop = FALSE]

raw_header <- squish(paste(squish(unlist(hdr[1, ])), squish(unlist(hdr[2, ]))))

names(pidba_name_map) <- deaccent(names(pidba_name_map))
clean_name <- unname(pidba_name_map[deaccent(raw_header)])
unmatched  <- is.na(clean_name)
if (any(unmatched)) {
  warning("Unmapped header(s) at column(s) ",
          paste(which(unmatched), collapse = ", "), ": ",
          paste(sQuote(raw_header[unmatched]), collapse = ", "),
          " — auto-named; update pidba_name_map.", call. = FALSE)
  clean_name[unmatched] <- make.names(raw_header[unmatched])
}
clean_name <- make.unique(clean_name, sep = "_")

missing_expected <- setdiff(pidba_name_map, clean_name)
if (length(missing_expected))
  message("Note: expected column(s) not present in this file: ",
          paste(missing_expected, collapse = ", "))

dat <- read_block(c(DATA_FIRST, DATA_LAST))
if (ncol(dat) < N_COL) dat[, (ncol(dat) + 1L):N_COL] <- NA_character_
dat <- dat[, seq_len(N_COL), drop = FALSE]
names(dat) <- clean_name
stopifnot(nrow(dat) == DATA_LAST - DATA_FIRST + 1L)

## Keep the spreadsheet row number — indispensable when reporting a bad record
dat$xl_row <- DATA_FIRST:DATA_LAST

## The workbook's own GRAND TOTALS line, used as an independent check below.
xl_totals_raw <- read_block(c(TOTALS_ROW, TOTALS_ROW))
if (ncol(xl_totals_raw) < N_COL) xl_totals_raw[, (ncol(xl_totals_raw) + 1L):N_COL] <- NA_character_
xl_totals <- as_pidba_numeric(unlist(xl_totals_raw[1, seq_len(N_COL)], use.names = FALSE))
names(xl_totals) <- clean_name

## ---------------------------------------------------------------------------
## 5. COLUMN GROUPS
## ---------------------------------------------------------------------------

ID_CHAR  <- c("Country", "CODE", "STAB", "INDEX", "COUNTY", "REFERENCES")
ID_NUM   <- c("lat", "long", "FIPS", "Area_SQ_MI")
DERIVED_COLS <- c("SAMPLE", "CLOVIS_FORMS", "NON_CLOVIS_FLUTED_TYPES",
                  "NON_FLUTED_VARIETIES")

## The raw artifact-count columns: CLOVIS (11) .. OTHER_FLUTED_UNTYPED (137).
## These are the only columns that carry primary counts; everything after them
## is a spreadsheet-derived roll-up.
TYPE_COLS <- clean_name[11:137]

## ---------------------------------------------------------------------------
## 6. CLEAN
## ---------------------------------------------------------------------------

pidba <- dat

for (v in intersect(ID_CHAR, names(pidba)))  pidba[[v]] <- as_pidba_character(pidba[[v]])
for (v in c(ID_NUM, TYPE_COLS, DERIVED_COLS)) {
  if (v %in% names(pidba)) pidba[[v]] <- as_pidba_numeric(pidba[[v]])
}

## Area is square miles in this workbook; carry both units.
pidba$Area_SQ_KM <- pidba$Area_SQ_MI * SQ_MI_TO_SQ_KM

## -- 6a. Country ------------------------------------------------------------
## Casing has been inconsistent ("Canada"/"CANADA") in past versions and at
## least one record once carried a stray numeric in the Country cell; recover
## it from CODE where possible.
CODE_TO_COUNTRY <- c(
  setNames(rep("US", 52), c(state.abb, "DC", "WASHINGTON, D.C.")),
  setNames(rep("CANADA", 13),
           c("ALB", "BC", "MAN", "NB", "NL", "NFLD", "NWT", "NS", "NU",
             "ONT", "PEI", "QUE", "SASK")),
  "Yukon" = "CANADA"
)

pidba$Country_raw <- pidba$Country
pidba$Country <- toupper(squish(pidba$Country))
bad_country <- is.na(pidba$Country) | !grepl("^[A-Z ]+$", pidba$Country)
pidba$Country[bad_country] <- unname(CODE_TO_COUNTRY[pidba$CODE[bad_country]])

## -- 6b. Administrative unit + region --------------------------------------
US_NAME <- c(setNames(state.name, state.abb),
             "DC" = "District of Columbia",
             "WASHINGTON, D.C." = "District of Columbia")
CA_NAME <- c("ALB" = "Alberta", "BC" = "British Columbia", "MAN" = "Manitoba",
             "NB" = "New Brunswick", "NL" = "Newfoundland and Labrador",
             "NFLD" = "Newfoundland and Labrador",
             "NWT" = "Northwest Territories", "NS" = "Nova Scotia",
             "NU" = "Nunavut", "ONT" = "Ontario",
             "PEI" = "Prince Edward Island", "QUE" = "Quebec",
             "SASK" = "Saskatchewan", "Yukon" = "Yukon")
COUNTRY_TITLE <- c("US" = "United States", "CANADA" = "Canada",
                   "MEXICO" = "Mexico", "BELIZE" = "Belize",
                   "GUATEMALA" = "Guatemala", "EL SALVADOR" = "El Salvador",
                   "HONDURAS" = "Honduras", "NICARAGUA" = "Nicaragua",
                   "COSTA RICA" = "Costa Rica", "PANAMA" = "Panama")

pidba$ADMIN_UNIT <- dplyr::case_when(
  pidba$Country == "US"     ~ unname(US_NAME[pidba$CODE]),
  pidba$Country == "CANADA" ~ unname(CA_NAME[pidba$CODE]),
  TRUE                      ~ unname(COUNTRY_TITLE[pidba$Country])
)
pidba$REGION <- dplyr::case_when(
  pidba$Country == "US"     ~ "United States",
  pidba$Country == "CANADA" ~ "Canada",
  TRUE                      ~ "Central American Nations"   # incl. Mexico, per PIDBA usage
)

## -- 6b2. Transposed coordinates -------------------------------------------
swapped <- !is.na(pidba$lat) & !is.na(pidba$long) &
  abs(pidba$lat) > 90 & abs(pidba$long) <= 90
coords_swapped <- pidba[swapped, c("xl_row", "Country", "CODE", "COUNTY", "lat", "long")]
if (FIX_SWAPPED_COORDS && any(swapped)) {
  tmp <- pidba$lat[swapped]
  pidba$lat[swapped]  <- pidba$long[swapped]
  pidba$long[swapped] <- tmp
}

## -- 6c. Counts -------------------------------------------------------------
if (COUNTS_NA_TO_ZERO) {
  for (v in TYPE_COLS) pidba[[v]][is.na(pidba[[v]])] <- 0
}
for (v in TYPE_COLS) pidba[[v]] <- as.integer(round(pidba[[v]]))

## -- 6d. Derived columns ----------------------------------------------------
## SAMPLE, CLOVIS_FORMS, NON_CLOVIS_FLUTED_TYPES and NON_FLUTED_VARIETIES are
## Excel formulas; the cached values are kept as *_xl for comparison and the
## working columns are recomputed from the type columns.
CLOVIS_GROUP    <- clean_name[11:13]    # CLOVIS, ROSS_COUNTY, CLOVIS_VARIANT
NONCLOVIS_GROUP <- clean_name[14:30]    # WAISTED_FLUTED .. HOLCOMB_NICOLAS
NONFLUTED_GROUP <- clean_name[31:136]   # SUWANNEE .. CHINDADN

rsum <- function(df, cols) as.integer(rowSums(as.matrix(df[, cols, drop = FALSE]), na.rm = TRUE))

pidba$SAMPLE_xl                  <- as_pidba_numeric(dat$SAMPLE)
pidba$CLOVIS_FORMS_xl            <- as_pidba_numeric(dat$CLOVIS_FORMS)
pidba$NON_CLOVIS_FLUTED_TYPES_xl <- as_pidba_numeric(dat$NON_CLOVIS_FLUTED_TYPES)
pidba$NON_FLUTED_VARIETIES_xl    <- as_pidba_numeric(dat$NON_FLUTED_VARIETIES)

if (RECOMPUTE_DERIVED) {
  pidba$CLOVIS_FORMS            <- rsum(pidba, CLOVIS_GROUP)
  pidba$NON_CLOVIS_FLUTED_TYPES <- rsum(pidba, NONCLOVIS_GROUP)
  pidba$NON_FLUTED_VARIETIES    <- rsum(pidba, NONFLUTED_GROUP)
  pidba$SAMPLE                  <- rsum(pidba, TYPE_COLS)
}

## Per-1000-sq-km rates, rebuilt from the (converted) area column.
rate_src <- c(FOLSOM_per_1000_sq_km     = "FOLSOM",
              CUMBERLAND_per_1000_sq_km = "CUMBERLAND",
              SUWANEE_per_1000_sq_km    = "SUWANNEE",
              SIMPSON_per_1000_sq_km    = "SIMPSON",
              SAMPLE_per_1000_sq_km     = "SAMPLE")
for (nm in names(rate_src))
  pidba[[nm]] <- ifelse(is.na(pidba$Area_SQ_KM) | pidba$Area_SQ_KM == 0, NA_real_,
                        pidba[[rate_src[nm]]] / pidba$Area_SQ_KM * 1000)
pidba$SUWANEE_SIMPSON_per_1000_sq_km <-
  ifelse(is.na(pidba$Area_SQ_KM) | pidba$Area_SQ_KM == 0, NA_real_,
         (pidba$SUWANNEE + pidba$SIMPSON) / pidba$Area_SQ_KM * 1000)

## -- 6e. Column order -------------------------------------------------------
front <- c("xl_row", "Country", "CODE", "STAB", "INDEX", "COUNTY",
           "ADMIN_UNIT", "REGION", "lat", "long", "FIPS",
           "Area_SQ_MI", "Area_SQ_KM", "SAMPLE")
pidba <- pidba[, c(front,
                   TYPE_COLS,
                   c("NON_CLOVIS_FLUTED_TYPES", "NON_FLUTED_VARIETIES", "CLOVIS_FORMS"),
                   RATE_COLS,
                   "REFERENCES",
                   c("SAMPLE_xl", "CLOVIS_FORMS_xl", "NON_CLOVIS_FLUTED_TYPES_xl",
                     "NON_FLUTED_VARIETIES_xl", "Country_raw"))]

## ---------------------------------------------------------------------------
## 7. DATA-QUALITY CHECKS
## ---------------------------------------------------------------------------

qc <- list()

qc$n_records <- nrow(pidba)

qc$sample_vs_types <- pidba %>%
  filter(SAMPLE_xl != SAMPLE) %>%
  select(xl_row, Country, CODE, COUNTY, SAMPLE_xl, SAMPLE_recomputed = SAMPLE)

qc$derived_stale <- bind_rows(
  pidba %>% filter(CLOVIS_FORMS_xl != CLOVIS_FORMS) %>%
    transmute(xl_row, column = "CLOVIS_FORMS", spreadsheet = CLOVIS_FORMS_xl, recomputed = CLOVIS_FORMS),
  pidba %>% filter(NON_CLOVIS_FLUTED_TYPES_xl != NON_CLOVIS_FLUTED_TYPES) %>%
    transmute(xl_row, column = "NON_CLOVIS_FLUTED_TYPES", spreadsheet = NON_CLOVIS_FLUTED_TYPES_xl, recomputed = NON_CLOVIS_FLUTED_TYPES),
  pidba %>% filter(NON_FLUTED_VARIETIES_xl != NON_FLUTED_VARIETIES) %>%
    transmute(xl_row, column = "NON_FLUTED_VARIETIES", spreadsheet = NON_FLUTED_VARIETIES_xl, recomputed = NON_FLUTED_VARIETIES)
)

qc$country_repaired <- pidba %>%
  filter(is.na(Country_raw) | toupper(Country_raw) != Country) %>%
  select(xl_row, Country_raw, Country, CODE, COUNTY)

qc$unmapped_admin <- pidba %>% filter(is.na(ADMIN_UNIT)) %>%
  count(Country, CODE, name = "n_records")

qc$missing_coords <- pidba %>% filter(is.na(lat) | is.na(long)) %>%
  select(xl_row, Country, CODE, COUNTY, lat, long)

qc$coords_swapped <- coords_swapped

qc$impossible_coords <- pidba %>%
  filter(!is.na(lat), !is.na(long), (lat < -90 | lat > 90 | long < -180 | long > 180)) %>%
  select(xl_row, Country, CODE, COUNTY, lat, long)

qc$missing_area <- sum(is.na(pidba$Area_SQ_MI))

qc$duplicate_units <- pidba %>%
  count(Country, CODE, COUNTY, name = "n") %>% filter(n > 1) %>% arrange(desc(n))

## ---------------------------------------------------------------------------
## 8. SUMMARY TABLE 1  — columns J..EJ against the spreadsheet GRAND TOTALS row
## ---------------------------------------------------------------------------

tbl_col_totals <- tibble(
  xl_col             = 10:140,
  spreadsheet_header = raw_header[10:140],
  column             = clean_name[10:140]
) %>%
  filter(column %in% names(pidba)) %>%
  rowwise() %>%
  mutate(grand_total = {
    v <- pidba[[column]]
    if (is.numeric(v)) sum(v, na.rm = TRUE) else NA_real_
  }) %>%
  ungroup() %>%
  mutate(spreadsheet_total = unname(xl_totals[column]),
         diff              = grand_total - spreadsheet_total,
         pct_of_sample     = round(100 * grand_total / sum(pidba$SAMPLE), 3))

## Column totals that disagree with the workbook's own GRAND TOTALS row
qc$col_total_check <- tbl_col_totals %>%
  filter(!is.na(spreadsheet_total), diff != 0) %>%
  select(xl_col, column, computed = grand_total, spreadsheet = spreadsheet_total, diff)

## Grand total as the spreadsheet defines it: the sum of the type columns.
GRAND_TOTAL <- sum(pidba$SAMPLE)

## ---------------------------------------------------------------------------
## 9. SUMMARY TABLE 2  — black box 1: ARTIFACTS BY CATEGORY
## ---------------------------------------------------------------------------

## category -> subtype -> the cleaned columns that make it up.
## The groupings follow the tags carried in spreadsheet header rows 12/13
## ("Dalton", "sn", "cn", "escn") and reproduce the published subtotals exactly.
category_def <- list(
  list(cat = "Clovis and related types", sub = NA,
       cols = CLOVIS_GROUP),
  list(cat = "Other Fluted Untyped", sub = NA,
       cols = "OTHER_FLUTED_UNTYPED"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Waisted Fluted",             cols = "WAISTED_FLUTED"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Fish Tail",                  cols = "FISHTAIL"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Folsom",                     cols = "FOLSOM"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Midland",                    cols = "MIDLAND"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Redstone",                   cols = "REDSTONE"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Cumberland",                 cols = "CUMBERLAND"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Gainey",                     cols = "GAINEY"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Wheeler",                    cols = "WHEELER"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Pelican",                    cols = "PELICAN"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "West Athens Hill-Bull Brook",cols = c("WEST_ATHENS_HILL", "BULL_BROOK")),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Vail-Debert",                cols = "Vail_DEBERT"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Barnes",                     cols = "BARNES"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Northumberland",             cols = "NORTHUMBERLAND"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Crowfield",                  cols = "CROWFIELD"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Michaud-Neponset",           cols = "MICHAUD_NEPONSET"),
  list(cat = "Non-Clovis Typed Fluted Points", sub = "Holcombe-Nicholas",          cols = "HOLCOMB_NICOLAS"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Suwannee",            cols = "SUWANNEE"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Simpson",             cols = "SIMPSON"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Beaver Lake",         cols = "BEAVER_LAKE"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Quad",                cols = "QUAD"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Coldwater",           cols = "COLDWATER"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Hinds",               cols = "HINDS"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Plainview",           cols = "PLAINVIEW"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Goshen",              cols = "GOSHEN"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Agate Basin",         cols = "AGATE_BASIN"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Hell Gap",            cols = "HELL_GAP"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Angostura",           cols = "ANGOSTURA"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Scottsbluff",         cols = "SCOTTSBLUFF"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Milnesand",           cols = "MILNESAND"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Alberta",             cols = "ALBERTA"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Wilson",              cols = "WILSON"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Jimmy Allen/Frederick",cols = "JIMMY_ALLEN_FREDERICK"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Eden",                cols = "EDEN"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Cody",                cols = "CODY"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Cody Knife",          cols = "CODY_KNIFE"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Packard",             cols = "PACKARD"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Pryor Stemmed*",      cols = "PRYOR_STEMMED"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Lovell Constricted*", cols = "LOVELL_CONSTRICTED"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Browns Valley*",      cols = "BROWNS_VALLEY"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Arkabutla*",          cols = "ARKABUTLA"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Ste Anne/Varney",     cols = "STE_ANNE_VARNEY"),
  list(cat = "Unfluted Lanceolates (Most Presumed Post-Clovis)", sub = "Unfluted Lanceolate", cols = "UNFLUTED_LANCEOLATE"),
  list(cat = "PreClovis Types", sub = "Haw River (possible Pre-Clovis)", cols = "HAW_RIVER"),
  list(cat = "Northern Forms", sub = "Mesa",      cols = "MESA"),
  list(cat = "Northern Forms", sub = "Sluiceway", cols = "SLUICEWAY"),
  list(cat = "Northern Forms", sub = "Chindadn",  cols = "CHINDADN"),
  list(cat = "Dalton and Dalton Variants", sub = "Hi-Lo",       cols = "HI_LO"),
  list(cat = "Dalton and Dalton Variants", sub = "Golondrina",  cols = "GOLONDRINA"),
  list(cat = "Dalton and Dalton Variants", sub = "Dalton (various types)",
       cols = c("HARPETH_RIVER", "MESERVE", "DALTON", "BASALLY_THINNED_DALTON",
                "LANCEOLATE_DALTON", "SIDE_NOTCHED_DALTON", "GREENBRIER_DALTON",
                "NUCKOLLS_DALTON")),
  list(cat = "Dalton and Dalton Variants", sub = "Hardaway",
       cols = c("HARDAWAY_DALTON", "HARDAWAY_BLADE")),
  list(cat = "Dalton and Dalton Variants", sub = "San Patrice var. Hope",      cols = "SAN_PATRICE_var._Hope"),
  list(cat = "Dalton and Dalton Variants", sub = "San Patrice var. St. Johns", cols = "SAN_PATRICE_var._St._Johns"),
  list(cat = "Dalton and Dalton Variants", sub = "Other San Patrice Dalton-like",
       cols = c("SAN_PATRICE_var._Brazos", "SAN_PATRICE_var._Kisatchie")),
  list(cat = "Side, Corner Notched, Bifurcate, Stemmed", sub = "Side Notched types",
       cols = c("SAN_PATRICE_var._Dixon", "HARDAWAY_SIDE_NOTCHED", "BOLEN_SIDE_NOTCHED",
                "UNTYPED_AND_TAYLOR_SIDE_NOTCHED", "SANTA_FE", "CACHE_RIVER",
                "BIG_SANDY", "BRECKENRiDGE", "UNION", "CHIPOLA")),
  list(cat = "Side, Corner Notched, Bifurcate, Stemmed", sub = "Corner Notched types",
       cols = c("GILCREST", "FAIRLAND", "SAN_PATRICE_var._Keithville",
                "SAN_PATRICE_var._Leaf_River", "SAN_PATRICE_var._GENEILL",
                "PALMER_CORNER_NOTCHED", "STILLWELL", "DECATUR", "LOST_LAKE",
                "PINE_TREE", "THEBES", "UNTYPED_AND_KIRK_CORNER_NOTCHED",
                "DOVETAIL_ST._CHARLES", "RICE_LOBED", "HARDIN", "JUDE_CAVE_SPRING")),
  list(cat = "Side, Corner Notched, Bifurcate, Stemmed", sub = "Bifurcate",
       cols = c("KANAWHA", "MACCORKLE", "LECROY", "ST._ALBANS", "BIFURCATE")),
  list(cat = "Side, Corner Notched, Bifurcate, Stemmed", sub = "Kirk Stemmed/Serrated",
       cols = c("KIRK_SERRATED", "KIRK_STEMMED")),
  list(cat = "Side, Corner Notched, Bifurcate, Stemmed", sub = "Misc San Patrice Notched",
       cols = "SAN_PATRICE_no_var."),
  list(cat = "Western Stemmed", sub = "Haskett",         cols = "HASKETT"),
  list(cat = "Western Stemmed", sub = "Cougar Mountain", cols = "COUGAR_MTN"),
  list(cat = "Western Stemmed", sub = "Windust",         cols = "WINDUST"),
  list(cat = "Western Stemmed", sub = "Cascade",         cols = "CASCADE"),
  list(cat = "Western Stemmed", sub = "Parman",          cols = "PARMAN"),
  list(cat = "Western Stemmed", sub = "Lind Coulee",     cols = "LIND_COULEE"),
  list(cat = "Western Stemmed", sub = "Lake Mohave",     cols = "LAKE_MOHAVE"),
  list(cat = "Western Stemmed", sub = "Bonneville",      cols = "BONNEVILLE"),
  list(cat = "Western Stemmed", sub = "Silver Lake",     cols = "SILVER_LAKE_"),
  list(cat = "Western Stemmed", sub = "Stubby",          cols = "STUBBY"),
  list(cat = "Western Stemmed", sub = "Generalized Western Stemmed", cols = "GBSS_GENERALIZED_WST"),
  list(cat = "Western Stemmed", sub = "Other Western Stemmed",
       cols = c("TAAN", "XIL", "XILJU", "CI_AMOL", "CI_BARBED", "COOPERS_FERRY")),
  list(cat = "Other Artifact Types", sub = "Crescents",                        cols = "CRESCENT"),
  list(cat = "Other Artifact Types", sub = "Edgefield Scraper",                cols = "EDGEFIELD_SCRAPER"),
  list(cat = "Other Artifact Types", sub = "Endscrapers",                      cols = "END_SCRAPER"),
  list(cat = "Other Artifact Types", sub = "Adzes",                            cols = "CFG_ADZE"),
  list(cat = "Other Artifact Types", sub = "Limaces",                          cols = "LIMACES"),
  list(cat = "Other Artifact Types", sub = "Prismatic Blades and Blade Cores", cols = "PRISMATIC_BLADES_CORES"),
  list(cat = "Other Artifact Types", sub = "Pieces Esquillees",                cols = "PIECES_ESQUILLEES"),
  list(cat = "Other Artifact Types", sub = "Groundstone/Grooved Abraders",     cols = "GROUNDSTONE_GROOVED_ABRADERS"),
  list(cat = "Other Artifact Types", sub = "Bone/Ivory Points, Rods, and Tools", cols = "BONE_IVORY_POINTS_RODS")
)

## Every count column must be used exactly once — a hard guarantee that the
## category table partitions the sample and reconciles to the grand total.
used <- unlist(lapply(category_def, `[[`, "cols"))
if (!setequal(used, TYPE_COLS) || anyDuplicated(used))
  warning("category_def does not partition the type columns: missing = ",
          paste(setdiff(TYPE_COLS, used), collapse = ", "),
          " ; duplicated = ", paste(used[duplicated(used)], collapse = ", "),
          call. = FALSE)

sum_cols <- function(cols) sum(as.matrix(pidba[, cols, drop = FALSE]), na.rm = TRUE)

tbl_category <- bind_rows(lapply(category_def, function(g)
  tibble(category = g$cat, subtype = g$sub, n = sum_cols(g$cols)))) %>%
  group_by(category) %>%
  mutate(category_total = sum(n)) %>%
  ungroup() %>%
  mutate(pct_of_total = round(100 * n / GRAND_TOTAL, 3))

tbl_category_totals <- tbl_category %>%
  distinct(category, category_total) %>%
  mutate(pct_of_total = round(100 * category_total / GRAND_TOTAL, 3)) %>%
  bind_rows(tibble(category = "GRAND TOTAL",
                   category_total = sum(.$category_total),
                   pct_of_total = 100))

## -- published values (26 August 2026 workbook, box 1), for verification -----
published_category <- c(
  "Clovis and related types" = 8823, "Other Fluted Untyped" = 7482,
  "Non-Clovis Typed Fluted Points" = 9020,
  "Unfluted Lanceolates (Most Presumed Post-Clovis)" = 9153,
  "PreClovis Types" = 29, "Northern Forms" = 448,
  "Dalton and Dalton Variants" = 9613,
  "Side, Corner Notched, Bifurcate, Stemmed" = 29832,
  "Western Stemmed" = 4832, "Other Artifact Types" = 24513,
  "GRAND TOTAL" = 103745)

published_subtype <- c(
  "Waisted Fluted"=45,"Fish Tail"=38,"Folsom"=4661,"Midland"=716,"Redstone"=440,
  "Cumberland"=993,"Gainey"=471,"Wheeler"=72,"Pelican"=146,
  "West Athens Hill-Bull Brook"=116,"Vail-Debert"=120,"Barnes"=195,
  "Northumberland"=54,"Crowfield"=164,"Michaud-Neponset"=421,"Holcombe-Nicholas"=368,
  "Suwannee"=723,"Simpson"=492,"Beaver Lake"=731,"Quad"=702,"Coldwater"=124,
  "Hinds"=70,"Plainview"=812,"Goshen"=117,"Agate Basin"=1088,"Hell Gap"=316,
  "Angostura"=427,"Scottsbluff"=363,"Milnesand"=143,"Alberta"=128,"Wilson"=74,
  "Jimmy Allen/Frederick"=421,"Eden"=255,"Cody"=643,"Cody Knife"=120,"Packard"=27,
  "Pryor Stemmed*"=85,"Lovell Constricted*"=10,"Browns Valley*"=8,"Arkabutla*"=9,
  "Ste Anne/Varney"=136,"Unfluted Lanceolate"=1129,
  "Haw River (possible Pre-Clovis)"=29,"Mesa"=157,"Sluiceway"=213,"Chindadn"=78,
  "Hi-Lo"=524,"Golondrina"=154,"Dalton (various types)"=7847,"Hardaway"=392,
  "San Patrice var. Hope"=212,"San Patrice var. St. Johns"=392,
  "Other San Patrice Dalton-like"=92,"Side Notched types"=5439,
  "Corner Notched types"=18310,"Bifurcate"=4798,"Kirk Stemmed/Serrated"=768,
  "Misc San Patrice Notched"=517,"Haskett"=194,"Cougar Mountain"=181,
  "Windust"=529,"Cascade"=269,"Parman"=380,"Lind Coulee"=10,"Lake Mohave"=650,
  "Bonneville"=389,"Silver Lake"=511,"Stubby"=115,
  "Generalized Western Stemmed"=1482,"Other Western Stemmed"=122,
  "Crescents"=2804,"Edgefield Scraper"=220,"Endscrapers"=12750,"Adzes"=870,
  "Limaces"=155,"Prismatic Blades and Blade Cores"=4609,"Pieces Esquillees"=2499,
  "Groundstone/Grooved Abraders"=311,"Bone/Ivory Points, Rods, and Tools"=295)

qc$category_check <- bind_rows(
  tbl_category %>% filter(!is.na(subtype)) %>%
    transmute(level = "subtype", label = subtype, computed = n,
              published = unname(published_subtype[subtype])),
  tbl_category_totals %>%
    transmute(level = "category", label = category, computed = category_total,
              published = unname(published_category[category]))
) %>% mutate(diff = computed - published) %>% filter(is.na(diff) | diff != 0)

## ---------------------------------------------------------------------------
## 10. SUMMARY TABLE 3 — black box 2: ARTIFACTS BY POLITICAL ADMIN UNIT
## ---------------------------------------------------------------------------

## Units with no records in the database still belong in the published table.
empty_units <- tibble(
  REGION     = c("Canada", "Canada", "Central American Nations"),
  ADMIN_UNIT = c("Newfoundland and Labrador", "Nunavut", "Nicaragua"),
  n          = 0L
)

tbl_admin <- pidba %>%
  group_by(REGION, ADMIN_UNIT) %>%
  summarise(n = sum(SAMPLE), n_records = dplyr::n(), .groups = "drop") %>%
  bind_rows(empty_units %>% mutate(n_records = 0L)) %>%
  arrange(factor(REGION, levels = c("United States", "Canada",
                                    "Central American Nations")),
          ADMIN_UNIT)

tbl_admin_totals <- tbl_admin %>%
  group_by(REGION) %>% summarise(total = sum(n), .groups = "drop") %>%
  bind_rows(tibble(REGION = "Grand Total", total = sum(.$total)))

## -- published values (26 August 2026 workbook, box 2) ----------------------
## Hawaii is shown as "n/a" in the published box and is carried as NA here.
published_admin <- c(
  Alabama=4824, Alaska=501, Arizona=188, Arkansas=1892, California=3248,
  Colorado=2272, Connecticut=100, Delaware=56, Florida=4597, Georgia=3174,
  Hawaii=NA, Idaho=309, Illinois=5974, Indiana=2816, Iowa=288, Kansas=497,
  Kentucky=2498, Louisiana=1251, Maine=1328, Maryland=669, Massachusetts=2401,
  Michigan=822, Minnesota=474, Mississippi=3957, Missouri=899, Montana=416,
  Nebraska=660, Nevada=2404, `New Hampshire`=188, `New Jersey`=934,
  `New Mexico`=2670, `New York`=1199, `North Carolina`=3476, `North Dakota`=730,
  Ohio=9151, Oklahoma=1607, Oregon=1483, Pennsylvania=2093, `Rhode Island`=11,
  `South Carolina`=6505, `South Dakota`=99, Tennessee=8332, Texas=6039,
  Utah=1295, Vermont=97, Virginia=1428, Washington=258, `West Virginia`=130,
  Wisconsin=1055, Wyoming=1381, `District of Columbia`=3,
  Alberta=294, `British Columbia`=22, Manitoba=49, `New Brunswick`=15,
  `Newfoundland and Labrador`=0, `Northwest Territories`=3, `Nova Scotia`=2774,
  Nunavut=0, Ontario=1163, `Prince Edward Island`=25, Quebec=108,
  Saskatchewan=109, Yukon=7,
  Mexico=361, Belize=65, Guatemala=8, `El Salvador`=2, `Costa Rica`=12,
  Honduras=2, Nicaragua=0, Panama=47)

published_admin_totals <- c("United States" = 98679, "Canada" = 4569,
                            "Central American Nations" = 497,
                            "Grand Total" = 103745)

qc$admin_check <- bind_rows(
  tbl_admin %>% transmute(level = "unit", label = ADMIN_UNIT, computed = n,
                          published = unname(published_admin[ADMIN_UNIT])),
  tbl_admin_totals %>% transmute(level = "region", label = REGION,
                                 computed = total,
                                 published = unname(published_admin_totals[REGION]))
) %>% mutate(diff = computed - published) %>% filter(is.na(diff) | diff != 0)

## ---------------------------------------------------------------------------
## 11. SUMMARY TABLE 4 — black box 3: BY CATEGORY, 2010 vs 2026
##     The 2010 column is historical (sample as of 24 May 2010) and cannot be
##     recomputed; it is carried as a transcribed constant. The 2026 column is
##     computed from the data above.
## ---------------------------------------------------------------------------

sample_2010 <- tribble(
  ~level,      ~label,                                 ~n_2010,
  "category",  "Clovis and Related Types",              "4498",
  "category",  "Other Fluted Untyped",                  "7408",
  "category",  "Non-Clovis Typed Fluted Points",        "4651",
  "subtype",   "Waisted Fluted",                        "n/a",
  "subtype",   "Fish Tail",                             "n/a",
  "subtype",   "Folsom",                                "2141**",
  "subtype",   "Midland",                               "396",
  "subtype",   "Redstone",                              "314",
  "subtype",   "Cumberland",                            "944",
  "subtype",   "Gainey",                                "112",
  "subtype",   "Wheeler",                               "57",
  "subtype",   "Pelican",                               "14",
  "subtype",   "West Athens Hill-Bull Brook",           "n/a",
  "subtype",   "Vail-Debert",                           "107",
  "subtype",   "Barnes",                                "316",
  "subtype",   "Northumberland",                        "54",
  "subtype",   "Crowfield",                             "100",
  "subtype",   "Michaud-Neponset",                      "n/a",
  "subtype",   "Holcombe-Nicholas",                     "96",
  "category",  "Unfluted Lanceolates",                  "2360",
  "subtype",   "Suwannee",                              "563",
  "subtype",   "Simpson",                               "129",
  "subtype",   "Beaver Lake",                           "553",
  "subtype",   "Quad",                                  "536",
  "subtype",   "Coldwater",                             "120",
  "subtype",   "Hinds",                                 "66",
  "subtype",   "Plainview",                             "8",
  "subtype",   "Goshen",                                "31",
  "subtype",   "Agate Basin",                           "131",
  "subtype",   "Hell Gap",                              "34",
  "subtype",   "Angostura",                             "3",
  "subtype",   "Scottsbluff",                           "9",
  "subtype",   "Milnesand",                             "3",
  "subtype",   "Alberta",                               "2",
  "subtype",   "Wilson",                                "n/a",
  "subtype",   "Jimmy Allen/Frederick",                 "1",
  "subtype",   "Eden",                                  "n/a",
  "subtype",   "Cody",                                  "n/a",
  "subtype",   "Cody Knife",                            "n/a",
  "subtype",   "Packard",                               "n/a",
  "subtype",   "Pryor Stemmed*",                        "n/a",
  "subtype",   "Lovell Constricted*",                   "n/a",
  "subtype",   "Browns Valley*",                        "n/a",
  "subtype",   "Arkabutla*",                            "9",
  "subtype",   "Ste Anne/Varney",                       "0",
  "subtype",   "Unfluted Lanceolate",                   "162",
  "category",  "PreClovis Types",                       "0",
  "subtype",   "Haw River",                             "0",
  "category",  "Northern Forms",                        "0",
  "subtype",   "Mesa",                                  "0",
  "subtype",   "Sluiceway",                             "0",
  "subtype",   "Chindadn",                              "0",
  "category",  "Dalton and Dalton Variants",            "3049",
  "subtype",   "Hi-Lo",                                 "118",
  "subtype",   "Golondrina",                            "n/a",
  "subtype",   "Dalton (various types)",                "2621",
  "subtype",   "Hardaway",                              "213",
  "subtype",   "San Patrice var. Hope",                 "n/a",
  "subtype",   "San Patrice var. St. Johns",            "97",
  "subtype",   "Other San Patrice Dalton-like",         "n/a",
  "category",  "Side, Corner Notch, Bifurcate, Stemmed","7743",
  "subtype",   "Side Notched types",                    "865",
  "subtype",   "Corner Notched types",                  "6509",
  "subtype",   "Bifurcate",                             "151",
  "subtype",   "Kirk Stemmed/Serrated",                 "109",
  "subtype",   "Misc San Patrice Notched",              "109",
  "category",  "Western Stemmed",                       "0",
  "subtype",   "Haskett",                               "0",
  "subtype",   "Cougar Mountain",                       "0",
  "subtype",   "Windust",                               "0",
  "subtype",   "Cascade",                               "0",
  "subtype",   "Parman",                                "0",
  "subtype",   "Lind Coulee",                           "0",
  "subtype",   "Lake Mohave",                           "0",
  "subtype",   "Bonneville",                            "0",
  "subtype",   "Silver Lake",                           "0",
  "subtype",   "Stubby",                                "0",
  "subtype",   "Generalized Western Stemmed",           "0",
  "subtype",   "Other Western Stemmed",                 "0",
  "category",  "Other Artifact Types",                  "0",
  "subtype",   "Crescents",                             "0",
  "subtype",   "Edgefield Scraper",                     "0",
  "subtype",   "Endscrapers",                           "0",
  "subtype",   "Adzes",                                 "0",
  "subtype",   "Limaces",                               "0",
  "subtype",   "Prismatic Blades and Blade Cores",      "0",
  "subtype",   "Pieces Esquillees",                     "0",
  "subtype",   "Groundstone/Grooved Abraders",          "0",
  "subtype",   "Bone/Ivory Points, Rods, and Tools",    "0",
  "category",  "Total Sample",                          "29709"
)

## Labels used in box 3 that differ from box 1
label_2026 <- c("Clovis and Related Types"              = "Clovis and related types",
                "Unfluted Lanceolates"                  = "Unfluted Lanceolates (Most Presumed Post-Clovis)",
                "Side, Corner Notch, Bifurcate, Stemmed"= "Side, Corner Notched, Bifurcate, Stemmed",
                "Haw River"                             = "Haw River (possible Pre-Clovis)")

n_2026_lookup <- c(
  setNames(tbl_category_totals$category_total, tbl_category_totals$category),
  setNames(tbl_category$n[!is.na(tbl_category$subtype)],
           tbl_category$subtype[!is.na(tbl_category$subtype)]),
  "Total Sample" = GRAND_TOTAL)

tbl_2010_2026 <- sample_2010 %>%
  mutate(
    key       = ifelse(label %in% names(label_2026), unname(label_2026[label]), label),
    n_2026    = unname(n_2026_lookup[key]),
    n_2010_num = suppressWarnings(as.numeric(gsub("[^0-9.]", "", n_2010))),
    n_2010_num = ifelse(grepl("n/a", n_2010, fixed = TRUE), NA_real_, n_2010_num),
    change    = n_2026 - n_2010_num,
    pct_change = ifelse(is.na(n_2010_num) | n_2010_num == 0, NA_real_,
                        round(100 * (n_2026 - n_2010_num) / n_2010_num, 1))
  ) %>%
  select(level, label, n_2010, n_2010_num, n_2026, change, pct_change)

attr(tbl_2010_2026, "footnotes") <- c(
  "*   Sample as of 24 May 2010.",
  "**  Total included 10 Sedgwick, thought at the time to be Folsom, since removed per Morrow et al. 2022:57-58.",
  "*** Total reported as 29,393 in the 2010 AENA paper, 29,737 in the Excel file used to generate these numbers; differences reflect types no longer used.",
  "n/a Not considered in 2010, or reported under a different category.")

published_2026_box3 <- c(
  "Clovis and Related Types"=8823,"Other Fluted Untyped"=7482,
  "Non-Clovis Typed Fluted Points"=9020,"Unfluted Lanceolates"=9153,
  "PreClovis Types"=29,"Haw River"=29,"Northern Forms"=448,
  "Dalton and Dalton Variants"=9613,
  "Side, Corner Notch, Bifurcate, Stemmed"=29832,"Western Stemmed"=4832,
  "Other Artifact Types"=24513,"Total Sample"=103745)

qc$box3_check <- tbl_2010_2026 %>%
  filter(label %in% names(published_2026_box3)) %>%
  transmute(label, computed = n_2026,
            published = unname(published_2026_box3[label]),
            diff = computed - published) %>%
  filter(is.na(diff) | diff != 0)

## ---------------------------------------------------------------------------
## 12. REPORT
## ---------------------------------------------------------------------------

pidba_report <- function() {
  hr <- function() cat(strrep("-", 78), "\n")
  cat("\nPIDBA MASTER LOCATIONAL DATABASE — 26 August 2026\n"); hr()
  cat("Records                 :", format(qc$n_records, big.mark = ","), "\n")
  cat("Columns                 :", ncol(pidba), "\n")
  cat("Grand total (all types) :", format(GRAND_TOTAL, big.mark = ","), "\n")
  cat("Countries               :", paste(sort(unique(pidba$Country)), collapse = ", "), "\n")
  hr()
  cat("DATA-QUALITY CHECKS\n")
  cat("  SAMPLE != sum of type columns (in workbook) :", nrow(qc$sample_vs_types), "row(s)\n")
  cat("  Stale cached roll-up cells                  :", nrow(qc$derived_stale), "cell(s)\n")
  cat("  Column totals != GRAND TOTALS row           :", nrow(qc$col_total_check), "column(s)\n")
  cat("  Country field repaired                      :", nrow(qc$country_repaired), "row(s)\n")
  cat("  Records with no admin-unit mapping          :", sum(qc$unmapped_admin$n_records), "\n")
  cat("  Records missing lat/long                    :", nrow(qc$missing_coords), "\n")
  cat("  Lat/long pairs transposed (and swapped back):", nrow(qc$coords_swapped), "\n")
  cat("  Records still out-of-range lat/long         :", nrow(qc$impossible_coords), "\n")
  cat("  Records missing Area_SQ_MI                  :", qc$missing_area, "\n")
  hr()
  cat("RECONCILIATION AGAINST THE PUBLISHED SUMMARY BOXES\n")
  cat("  Box 1 (by category)   mismatches:", nrow(qc$category_check), "\n")
  if (nrow(qc$category_check)) print(as.data.frame(qc$category_check), row.names = FALSE)
  cat("  Box 2 (by admin unit) mismatches:", nrow(qc$admin_check), "\n")
  if (nrow(qc$admin_check)) print(as.data.frame(qc$admin_check), row.names = FALSE)
  cat("  Box 3 (2010 vs 2026)  mismatches:", nrow(qc$box3_check), "\n")
  if (nrow(qc$box3_check)) print(as.data.frame(qc$box3_check), row.names = FALSE)
  hr()
  invisible(NULL)
}

pidba_report()

## ---------------------------------------------------------------------------
## 13. EXPORT
## ---------------------------------------------------------------------------

write.csv(pidba,            "PIDBA_2026_CLEAN.csv",            row.names = FALSE, na = "")
write.csv(tbl_col_totals,   "PIDBA_2026_column_totals.csv",    row.names = FALSE, na = "")
write.csv(tbl_category,     "PIDBA_2026_by_category.csv",      row.names = FALSE, na = "")
write.csv(tbl_admin,        "PIDBA_2026_by_admin_unit.csv",    row.names = FALSE, na = "")
write.csv(tbl_2010_2026,    "PIDBA_2026_vs_2010.csv",          row.names = FALSE, na = "")
