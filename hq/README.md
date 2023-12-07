# Running on karolina

# Intialize Python environment (only once)
$ ml load Python
$ cd /PATH/TO/PATH/TO/fortran_cloud/hq/
$ python3 -m venv venv
$ source venv/bin/activate
$ pip3 install --upgrade pip
$ pip3 install zmq
$ pip3 install hyperqueue

# Start HQ on login node
EDIT: /PATH/TO/fortran_cloud/hq/worker_init.sh
and set corrent path to /PATH/TO/fortran_cloud/hq/
$ hq server start
$ hq alloc add slurm --time-limit=3m --worker-start-cmd="source /PATH/TO/fortran_cloud/hq/worker_init.sh" -- -A OPEN-28-69 -p qcpu_ex

# Start broker
python3 broker.py

# Start producer
python3 producer.py
