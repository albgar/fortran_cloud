## Python implementation of producer-consumer toy workflow with HQ and a special broker

This is work in progress by Ada Böhm, who has created a "broker"
object that has extra features beyond those of a simple proxy. It
leverages HyperQueue to create new tasks. The original branch is `hq-ada`
in `https://github.com/spirali/fortran_cloud`.


### Installation and execution

(Note: It seems that on some systems (e.g. Karolina) connecting from
the compute node to the login node is somehow filtered when ZeroMQ is
used (normal TCP/IP connection works and HQ itself works ok). So the
code is not able to send results back to the broker from the compute
node, because for sake of simplicity ZeroMQ is also used in the broker
code. But it is an internal data transfer and one can use raw TCP/IP
connection without breaking any API for consumer/producer.)


```
# Initialize Python environment (only once)
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
```

Note that, upon receiving a packet from the producer in its frontend,
the broker launches a "job" that simply connects to a listening
consumer (run when the worker starts), and then sends the result to
the broker's backend.  Just one consumer (identified by its port 5000 in the "job") is really active.
So, if the producer is fast, there might be a lot of HQ jobs trying to connect to the same consumer...