import grpc
from src.alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

def test_predict_sequence():
    channel = grpc.insecure_channel("localhost:50051")
    stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
    request = dna_model_pb2.PredictSequenceRequest(
        sequence="ACGT",
        organism=dna_model_pb2.ORGANISM_HOMO_SAPIENS,
        requested_outputs=[dna_model_pb2.OUTPUT_TYPE_ATAC]
    )
    response = stub.PredictSequence(request)
    print("PredictSequence response:", response)

def test_predict_interval():
    channel = grpc.insecure_channel("localhost:50051")
    stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
    request = dna_model_pb2.PredictIntervalRequest(
        interval=dna_model_pb2.Interval(chromosome="chr1", start=0, end=10),
        organism=dna_model_pb2.ORGANISM_HOMO_SAPIENS,
        requested_outputs=[dna_model_pb2.OUTPUT_TYPE_ATAC]
    )
    response = stub.PredictInterval(request)
    print("PredictInterval response:", response)

if __name__ == "__main__":
    test_predict_sequence()
    test_predict_interval() 