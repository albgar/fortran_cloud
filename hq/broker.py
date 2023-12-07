import zmq
import socket

def run_job(result_addr, data):
    print("JOB")
    context = zmq.Context()
    socket = context.socket(zmq.REQ)
    print("SENDING TO CONSUMER")
    socket.connect("tcp://localhost:5000")
    socket.send_multipart(data)
    print("RECEIVING FROM CONSUMER")
    response = socket.recv_multipart()
    socket.close()
    print("SENDING RESULT BACK TO BROKER")
    socket = context.socket(zmq.DEALER)
    socket.connect(result_addr)
    socket.send_multipart(response)
    print("JOB DONE")

def main():
    import hyperqueue as hq
    from hyperqueue.task.function import PythonEnv


    client = hq.Client() # python_env=PythonEnv(python_bin="/home/spirali/projects/hyperqueue/venv/bin/python"))

    context = zmq.Context()
    user_socket = context.socket(zmq.ROUTER)
    user_socket.bind("tcp://*:3445")

    result_socket = context.socket(zmq.DEALER)
    result_socket.bind("tcp://*:3447")

    result_addr = f"tcp://{socket.gethostname()}:3447"

    poller = zmq.Poller()
    poller.register(user_socket, zmq.POLLIN)
    poller.register(result_socket, zmq.POLLIN)

    print("Result address", result_addr)

    while True:
        ready = dict(poller.poll())
        if ready.get(user_socket) == zmq.POLLIN:
            print("CREATING NEW TASK")
            message = user_socket.recv_multipart()
            if message:
                #import multiprocessing
                #multiprocessing.Process(target=run_job, args=[message]).start()
                job = hq.Job()
                resources = hq.job.ResourceRequest(resources={"consumers": 1})
                job.function(run_job, args=[result_addr, message], resources=resources)
                client.submit(job)
        if ready.get(result_socket) == zmq.POLLIN:
            print("RESENDING RESULT")
            message = result_socket.recv_multipart()
            user_socket.send_multipart(message)
            #result_socket.send_multipart([message[0], b"Ok"])
            print("RESENDING FINISHED")


if __name__ == "__main__":
    main()
