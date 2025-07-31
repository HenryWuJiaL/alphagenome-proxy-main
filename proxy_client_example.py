
# 代理客户端使用示例
import grpc
from alphagenome.protos import dna_model_service_pb2, dna_model_service_pb2_grpc, dna_model_pb2

class AlphaGenomeProxyClient:
    def __init__(self, service_url="alphagenome-proxy-175461151316.us-central1.run.app:443"):
        self.service_url = service_url
        self.credentials = grpc.ssl_channel_credentials()
        self.channel = grpc.secure_channel(service_url, self.credentials)
        self.stub = dna_model_service_pb2_grpc.DnaModelServiceStub(self.channel)
    
    def predict_variant(self, chromosome, position, ref_base, alt_base, 
                       start=None, end=None, organism=dna_model_pb2.ORGANISM_HOMO_SAPIENS,
                       ontology_terms=None, requested_outputs=None):
        """预测变异影响"""
        
        # 设置默认值
        if start is None:
            start = position - 1000
        if end is None:
            end = position + 1000
        if ontology_terms is None:
            ontology_terms = ['UBERON:0001157']
        if requested_outputs is None:
            requested_outputs = [dna_model_pb2.OUTPUT_TYPE_RNA_SEQ]
        
        # 创建请求
        request = dna_model_service_pb2.PredictVariantRequest()
        
        # 设置区间
        request.interval.chromosome = chromosome
        request.interval.start = start
        request.interval.end = end
        
        # 设置变异
        request.variant.chromosome = chromosome
        request.variant.position = position
        request.variant.reference_bases = ref_base
        request.variant.alternate_bases = alt_base
        
        # 设置其他参数
        request.organism = organism
        
        # 设置输出类型
        for output_type in requested_outputs:
            request.requested_outputs.append(output_type)
        
        # 设置本体术语（修复字段名）
        for term in ontology_terms:
            ontology_term = request.ontology_terms.add()
            if term.startswith('UBERON:'):
                ontology_term.ontology_type = dna_model_pb2.ONTOLOGY_TYPE_UBERON
                ontology_term.id = int(term.split(':')[1])
            # 可以添加其他本体类型的处理
        
        # 发送请求
        return self.stub.PredictVariant(request, timeout=60)
    
    def close(self):
        """关闭连接"""
        self.channel.close()

# 使用示例
if __name__ == "__main__":
    # 创建客户端
    client = AlphaGenomeProxyClient()
    
    try:
        # 预测变异（对应官方示例）
        response = client.predict_variant(
            chromosome="chr22",
            position=36201698,
            ref_base="A",
            alt_base="C",
            start=35677410,
            end=36725986,
            ontology_terms=['UBERON:0001157'],
            requested_outputs=[dna_model_pb2.OUTPUT_TYPE_RNA_SEQ]
        )
        
        print("✅ 预测成功")
        print(f"响应类型: {type(response)}")
        
        # 分析响应数据
        if hasattr(response, 'output'):
            print(f"输出类型: {response.output.output_type}")
            if hasattr(response.output, 'data'):
                print(f"数据形状: {response.output.data.shape}")
        
    finally:
        client.close()
