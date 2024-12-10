
gunicorn --bind=0.0.0.0:3001 --access-logfile=- --worker-tmp-dir=/tmp --workers=10 -k uvicorn.workers.UvicornWorker config.wsgi:application
autocannon -c 100 -d 10 -p 10 "http://localhost:3001/api/v1/decision/?publisher=internal-testing-publisher&ad_types=text&campaign_types=community&format=json&placements%5B0%5D=video_card&div_ids=video_card"
autocannon -c 100 -d 10 -p 10 "https://kahfads.com/api/v1/decision/?publisher=internal-testing-publisher&ad_types=text&campaign_types=community&format=json&placements%5B0%5D=video_card&div_ids=video_card"