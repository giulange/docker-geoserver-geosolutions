#!/bin/bash

alreadyDone=0

alreadyDone=1
if [ "$alreadyDone" -ne 1 ]; then
  ogr2ogr \
    -f "PostgreSQL" \
    PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
    regions_sdg11-3-1_2022_2023.gpkg \
    -nln regions \
    -overwrite
fi

alreadyDone=1
if [ "$alreadyDone" -ne 1 ]; then
  ogr2ogr \
    -f "PostgreSQL" \
    PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
    regions_sdg11-3-1_2021_2022.gpkg \
    -nln regions \
    -append
fi

alreadyDone=1
if [ "$alreadyDone" -ne 1 ]; then
  ogr2ogr \
    -f "PostgreSQL" \
    PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
    municipalities_sdg11-3-1_2022_2023.gpkg \
    -nln municipalities \
    -overwrite
fi

alreadyDone=1
if [ "$alreadyDone" -ne 1 ]; then
  ogr2ogr \
    -f "PostgreSQL" \
    PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
    municipalities_sdg11-3-1_2021_2022.gpkg \
    -nln municipalities \
    -append
fi

ogr2ogr \
  -f "PostgreSQL" \
  PG:"host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver" \
  municipalities_renaturalization_2022_2023.gpkg \
  -nln renaturalization \
  -overwrite
