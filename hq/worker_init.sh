set -e

DIR=/home/boh126/projects/fortran_cloud/hq

ml load Python
cd $DIR
echo "Consumers initing"
source venv/bin/activate
python consumer.py 5000 &
python consumer.py 5001 & 
echo "Consumers inited"
