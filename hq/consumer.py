import zmq
import time
import sys

def main():
    if len(sys.argv) != 2:
        print("Usage: consumer <port>")
        return
    port = int(sys.argv[1])
    context = zmq.Context()
    socket = context.socket(zmq.REP)
    socket.bind(f"tcp://*:{port}")
    while True:
        data = socket.recv_multipart()
        time.sleep(1)
        socket.send_multipart(data)

if __name__ == "__main__":
    main()
