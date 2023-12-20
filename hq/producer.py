import zmq
import time
import sys

def main():
    port = 3445
    context = zmq.Context()
    socket = context.socket(zmq.DEALER)
    socket.connect(f"tcp://localhost:{port}")
    while True:
        print("SENDING DATA")
        socket.send(b"1234567890")
        while True:
            try:
                data = socket.recv(flags=zmq.NOBLOCK)
                print("RECEIVED DATA", data)
            except zmq.error.Again:
                break
        time.sleep(1)
if __name__ == "__main__":
    main()
