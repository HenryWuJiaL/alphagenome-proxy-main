import subprocess
import threading
import time
import os


def start_json_service():
    print("Starting JSON service on port 8000...")

    venv_python = os.path.join(os.getcwd(), "venv", "bin", "python")
    subprocess.run([
        venv_python, "-m", "uvicorn", "mock_json_service:app",
        "--host", "127.0.0.1", "--port", "8000", "--reload"
    ])


def start_grpc_proxy():
    print("Starting gRPC proxy on port 50051...")

    venv_python = os.path.join(os.getcwd(), "venv", "bin", "python")
    subprocess.run([
        venv_python, "-c",
        "from src.alphagenome.communication_proxy import serve; serve()"
    ])


def main():
    print("Starting AlphaGenome Services...")
    print("Press Ctrl+C to stop all services")


    json_thread = threading.Thread(target=start_json_service)
    json_thread.daemon = True
    json_thread.start()


    time.sleep(3)


    grpc_thread = threading.Thread(target=start_grpc_proxy)
    grpc_thread.daemon = True
    grpc_thread.start()

    try:

        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping services...")


if __name__ == "__main__":
    main()
