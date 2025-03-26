#docker exec -it postgres \
#  psql -U geoserver -d geoserver -x -c "SELECT * FROM public.regions LIMIT 1;"

echo "Count regions table:"
docker exec -it postgres \
  psql -U geoserver -d geoserver -x -c "SELECT COUNT(*) FROM public.regions;"

echo ""
echo "Count municipalities table:"
docker exec -it postgres \
  psql -U geoserver -d geoserver -x -c "SELECT COUNT(*) FROM public.municipalities;"

