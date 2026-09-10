PIDBA LOCATIONAL DATABASE
=========================

Data, references, and maps supporting the Paleoindian Database of the
Americas (PIDBA) -- a long-running, collaborative compilation of
Paleoindian and Early Archaic projectile point and stone tool records
across North America, reported at the county level and sourced from
the published and gray literature.

PIDBA's public-facing site is http://pidba.utk.edu/. This
repository holds the current (2026) locational database export, its
supporting reference list, a GIS package built from it, and a set of
distribution maps prepared for the Paleoamerican Odyssey 2026
conference.


CONTENTS
--------

PIDBA Locational Database 4 September 2026 Final.xlsx
    Current master database (the file to use). One row per U.S./
    Canadian county (or equivalent unit), with a count column for
    each projectile point / tool type or type group, plus the
    supporting reference(s) for each county's counts.

PIDBA Locational Database 26 August 2026 Final.xlsx
    Prior dated snapshot of the same database, kept for version
    history.

PIDBA Locational Database 4 September 2026 Final Table 3.pdf
    Summary table comparing artifact counts by category between the
    2010 sample and the current 2026 sample (see "Database growth,
    2010 to 2026" below).

PIDBA Database References 4 September 2026.docx
    Full supporting bibliography (~2,630 references) for the counts
    in the locational database, compiled by D.G. Anderson, D.S.
    Miller, D.T. Anderson, S. Perrot-Minnot, R. Rosencrance, G.
    Sanchez, and H.L. Smith.

PIDBA Database References 4 August 2026.docx
    Prior dated snapshot of the reference list.

PIDBA MAPS INTRODUCTION.docx
    Cover note for the map set below: context, permitted use, and
    citation.

PIDBA Maps 10 September 2026.pdf
    77 distribution maps (80-page PDF) plotting the database by
    type/type group, prepared for a poster session at the
    Paleoamerican Odyssey 2026 conference (15 October 2026).

PIDBA_GIS.zip
    GIS package built from the locational database -- shapefile,
    GeoPackage, and a column codebook. See below.


THE LOCATIONAL DATABASE
------------------------

The workbook's single sheet (PALEO POINT WORKING DATABASE) carries a
short title block in the first few rows (version date, grand total
sample size, source URL), followed by one row per county and a wide
set of count columns -- one per point/tool type, plus grouped columns
for closely related or historically-combined types (e.g., Waisted
Fluted, Vail/Debert, Michaud/Neponset, Holcombe/Nicholas). The final
column of each block cites the reference(s) the county's counts were
drawn from, keyed to the bibliography above.

As of the 4 September 2026 version, the database totals 103,745
reported artifacts.


GIS DATA (PIDBA_GIS.zip)
-------------------------

Unzipping PIDBA_GIS.zip gives a PIDBA_GIS/ folder with:

  - PIDBA_maps.shp (+ .shx, .dbf, .prj, .cpg)
        A county-level point layer built from the locational
        database, one attribute column per mapped type/type group.
  - PIDBA_maps.gpkg
        The same layer as a GeoPackage.
  - PIDBA_maps.zip
        A zipped copy of the shapefile component files (convenient
        for scripted download/unzip workflows).
  - PIDBA_map_columns.csv
        The codebook: for every mapped column, which source database
        column(s) it rolls up, its total count, and the number of
        counties reporting it.

Column codebook
~~~~~~~~~~~~~~~~
The mapped columns follow a consistent naming scheme: Map1-Map7 are
the seven top-level type groups; a letter suffix (Map3a, Map3b, ...)
breaks a group into its named types; and, for a few types with named
varieties, a trailing number (Map3d1, Map3d2; Map3i1...Map3i9) breaks
that type out further. PIDBA_map_columns.csv documents every level of
this hierarchy -- which source columns feed each map code, and its
total count and county count. The seven top-level groups:

  Code    Group                                          Total    Counties
  ----    -----                                         ------    --------
  Map1    Clovis and Untyped Fluted                     16,305       2,026
  Map2    Non-Clovis Fluted                               9,020       1,176
  Map3    Unfluted (presumed post-Clovis) Lanceolate       9,601         881
          Forms
  Map4    Western Stemmed                                 4,832          71
  Map5    Dalton and Related Forms                        9,613         737
  Map6    Early Holocene Side-Notched, Corner-Notched,    29,832         876
          Bifurcate, and Stemmed
  Map7    Unusual Tool Forms                             24,513         342

(Counts are as tabulated in the GIS attribute table and codebook;
they're drawn from the same underlying database but may lag the Excel
file by a few days of edits.)


MAPS
----

PIDBA Maps 10 September 2026.pdf contains 77 maps generated from the
database above -- overview maps for each top-level group plus
breakdowns by individual type. Per PIDBA MAPS INTRODUCTION.docx,
these (and the database/reference files) were prepared for the
Paleoamerican Odyssey 2026 conference and are also mirrored at:

  https://github.com/PIDBA/PaleoamericanOdyssey2026


DATABASE GROWTH, 2010 TO 2026
-------------------------------

...Final Table 3.pdf summarizes how the compiled sample has grown
since the last widely-cited (2010) tabulation:

                                              2010 sample   2026 sample
                                              -----------   -----------
  Total                                           29,709       103,745
  Clovis and Related Types                          4,498         8,823
  Non-Clovis Typed Fluted Points                    4,651         9,020
  Unfluted Lanceolates                              2,360         9,153
  Dalton and Dalton Variants                        3,049         9,613
  Side-, Corner-Notched, Bifurcate, Stemmed         7,743        29,832
  Western Stemmed                                       0         4,832
  Other Artifact Types (scrapers, adzes,                 0        24,513
  blades, etc.)

The full table (in the PDF) breaks each of these down to individual
named types.


CITATION AND USE
-----------------

Per PIDBA MAPS INTRODUCTION.docx: these files are meant to be used
and shared. Edits and additions are welcome (please mark them with
track changes or a distinct font color so they can be found and
merged). When citing this data, please acknowledge PIDBA 2026, or:

  Anderson, David G., D. Shane Miller, Thaddeus G. Bissett, J.
  Christopher Gillam, Eric C. Kansa, Sarah Whitcher Kansa, Ashley M.
  Smallwood, Joshua J. Wells, Andrew A. White, Stephen J. Yerka, et
  al. 2026. The Paleoindian Database of the Americas (PIDBA) and
  Early Human Settlement in the Americas: Current Understanding and
  Future Directions. In Paleoamerican Odyssey, 100 Years Beyond
  Folsom, edited by Jessi J. Halligan, Lily E. Dempsey, Nicholas K.
  Bentley, Cody L. Preston, Kurt Rademaker, and Michael R. Waters,
  pp. 573-592. Texas A&M University Press, College Station.
