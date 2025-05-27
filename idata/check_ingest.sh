#docker exec -it postgres \
#  psql -U geoserver -d geoserver -x -c "SELECT * FROM public.regions LIMIT 1;"

echo ""
echo "Count regions_indicators table:"
docker exec -it postgres \
  psql -U geoserver -d geoserver -x -c "SELECT COUNT(*) FROM public.regions_indicators;"

echo ""
echo "Count provinces_indicators table:"
docker exec -it postgres \
  psql -U geoserver -d geoserver -x -c "SELECT COUNT(*) FROM public.provinces_indicators;"

echo ""
echo "Count municipalities_indicators table:"
docker exec -it postgres \
  psql -U geoserver -d geoserver -x -c "SELECT COUNT(*) FROM public.municipalities_indicators;"

