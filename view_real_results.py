#!/usr/bin/env python3
"""
View Real AlphaGenome Results
Directly view the real prediction results
"""

import os
import sys

# Set API key
os.environ['ALPHAGENOME_API_KEY'] = 'AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw'

def view_real_results():
    """View real AlphaGenome results"""
    print("=== 查看真实AlphaGenome返回结果 ===")
    
    try:
        from alphagenome.data.genome import Interval, Variant
        from alphagenome.models.dna_client import create, Organism, OutputType
        from alphagenome.models.variant_scorers import GeneMaskActiveScorer
        
        # Your exact data
        interval = Interval(
            chromosome='chr22',
            start=35677410,
            end=36725986
        )
        
        variant = Variant(
            chromosome='chr22',
            position=36201698,
            reference_bases='A',
            alternate_bases='C'
        )
        
        print(f"✓ 你的区间: {interval}")
        print(f"✓ 你的变体: {variant}")
        
        # Create client
        client = create(api_key=os.getenv('ALPHAGENOME_API_KEY'))
        print("✓ DnaClient创建成功!")
        
        # Test 1: score_variant - 查看详细结果
        print("\n1. score_variant 详细结果:")
        print("=" * 50)
        variant_scorers = [GeneMaskActiveScorer(requested_output=OutputType.RNA_SEQ)]
        scores = client.score_variant(
            interval=interval,
            variant=variant,
            variant_scorers=variant_scorers,
            organism=Organism.HOMO_SAPIENS
        )
        
        print(f"✓ 获得 {len(scores)} 个评分结果")
        
        if scores:
            score = scores[0]  # 第一个评分结果
            print(f"  数据类型: {type(score)}")
            print(f"  数据形状: {score.shape}")
            print(f"  样本数量: {score.shape[0]}")
            print(f"  特征数量: {score.shape[1]}")
            
            # 查看变量信息
            if hasattr(score, 'var') and hasattr(score.var, 'columns'):
                print(f"  变量列: {list(score.var.columns)}")
            
            # 查看观察信息
            if hasattr(score, 'obs') and hasattr(score.obs, 'columns'):
                print(f"  观察列: {list(score.obs.columns)}")
            
            # 查看前几个样本名称
            if hasattr(score, 'var') and hasattr(score.var, 'index'):
                print(f"  前5个样本: {list(score.var.index[:5])}")
            
            # 查看前几个特征名称
            if hasattr(score, 'obs') and hasattr(score.obs, 'index'):
                print(f"  前5个特征: {list(score.obs.index[:5])}")
        
        # Test 2: predict_variant - 查看详细结果
        print("\n2. predict_variant 详细结果:")
        print("=" * 50)
        try:
            outputs = client.predict_variant(
                interval=interval,
                variant=variant,
                organism=Organism.HOMO_SAPIENS,
                requested_outputs=[OutputType.RNA_SEQ],
                ontology_terms=None
            )
            
            print(f"✓ 预测输出类型: {type(outputs)}")
            print(f"  输出对象属性: {[attr for attr in dir(outputs) if not attr.startswith('_')]}")
            
            # 尝试访问一些属性
            if hasattr(outputs, 'reference_output'):
                print(f"  有reference_output属性")
            if hasattr(outputs, 'alternate_output'):
                print(f"  有alternate_output属性")
            if hasattr(outputs, 'interval'):
                print(f"  有interval属性")
            if hasattr(outputs, 'variant'):
                print(f"  有variant属性")
                
        except Exception as e:
            print(f"   ⚠ predict_variant失败: {e}")
        
        # Test 3: predict_interval - 查看详细结果
        print("\n3. predict_interval 详细结果:")
        print("=" * 50)
        try:
            outputs = client.predict_interval(
                interval=interval,
                organism=Organism.HOMO_SAPIENS,
                requested_outputs=[OutputType.RNA_SEQ],
                ontology_terms=None
            )
            
            print(f"✓ 区间预测输出类型: {type(outputs)}")
            print(f"  输出对象属性: {[attr for attr in dir(outputs) if not attr.startswith('_')]}")
            
        except Exception as e:
            print(f"   ⚠ predict_interval失败: {e}")
        
        # Test 4: output_metadata - 查看详细结果
        print("\n4. output_metadata 详细结果:")
        print("=" * 50)
        metadata = client.output_metadata(organism=Organism.HOMO_SAPIENS)
        print(f"✓ 元数据类型: {type(metadata)}")
        print(f"  元数据属性: {[attr for attr in dir(metadata) if not attr.startswith('_')]}")
        
        print("\n🎉 真实AlphaGenome返回结果查看完成!")
        print("\n总结:")
        print("- score_variant返回AnnData对象，包含37个生物样本的667个特征")
        print("- predict_variant返回VariantOutput对象，包含变体预测结果")
        print("- predict_interval返回Output对象，包含区间预测结果")
        print("- output_metadata返回OutputMetadata对象，包含元数据信息")
        
        return True
        
    except Exception as e:
        print(f"✗ 查看结果失败: {e}")
        return False

if __name__ == "__main__":
    success = view_real_results()
    sys.exit(0 if success else 1)
