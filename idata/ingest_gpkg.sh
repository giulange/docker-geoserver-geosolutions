ogr2ogr \
  -f "PostgreSQL" \
  PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
  regions_sdg11-3-1_2022_2023.gpkg \
  -nln regions \
  -overwrite

ogr2ogr \
  -f "PostgreSQL" \
  PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
  regions_sdg11-3-1_2021_2022.gpkg \
  -nln regions \
  -append


ogr2ogr \
  -f "PostgreSQL" \
  PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
  municipalities_sdg11-3-1_2022_2023.gpkg \
  -nln municipalities \
  -overwrite

ogr2ogr \
  -f "PostgreSQL" \
  PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
  municipalities_sdg11-3-1_2021_2022.gpkg \
  -nln municipalities \
  -append
