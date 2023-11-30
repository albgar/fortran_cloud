import zmq
import time

context = zmq.Context()
socket = context.socket(zmq.REP)
socket.bind("tcp://*:3446")
while True:
    data = socket.recv_multipart()
    print("RECV", data)
    time.sleep(1)
    socket.send_multipart(data)