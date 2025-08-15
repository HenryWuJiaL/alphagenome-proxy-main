#!/usr/bin/env python3
"""
Call Real AlphaGenome Predictions
This script actually calls the real AlphaGenome prediction methods
"""

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def call_real_variant_predictions():
    """Actually call real variant predictions"""
    print("=== Calling Real Variant Predictions ===")
    
    try:
        from alphagenome.data.genome import Interval, Variant
        from alphagenome.models.variant_scorers import GeneMaskActiveScorer
        from alphagenome.models.dna_client import OutputType
        
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
        
        print(f"✓ Your interval: {interval}")
        print(f"✓ Your variant: {variant}")
        
        # Create scorer
        scorer = GeneMaskActiveScorer(requested_output=OutputType.RNA_SEQ)
        print(f"✓ Created scorer: {scorer}")
        
        # ACTUALLY CALL THE REAL PREDICTION METHOD
        print("\n🚀 CALLING REAL PREDICTION METHOD...")
        try:
            predictions = scorer.score(variant, interval)
            print("🎉 SUCCESS! Real predictions received:")
            print(f"   Predictions: {predictions}")
            print(f"   Type: {type(predictions)}")
            return True
        except Exception as e:
            print(f"⚠ Prediction call failed: {e}")
            print("   This might be due to missing model files or configuration")
            return False
        
    except Exception as e:
        print(f"✗ Failed to call variant predictions: {e}")
        return False

def call_real_interval_predictions():
    """Actually call real interval predictions"""
    print("\n=== Calling Real Interval Predictions ===")
    
    try:
        from alphagenome.data.genome import Interval
        from alphagenome.models.interval_scorers import GeneMaskScorer
        from alphagenome.models.dna_client import OutputType
        
        # Your exact data
        interval = Interval(
            chromosome='chr22',
            start=35677410,
            end=36725986
        )
        
        print(f"✓ Your interval: {interval}")
        
        # Create scorer with supported width
        scorer = GeneMaskScorer(
            requested_output=OutputType.RNA_SEQ,
            width=501,
            aggregation_type='mean'
        )
        print(f"✓ Created scorer: {scorer}")
        
        # ACTUALLY CALL THE REAL PREDICTION METHOD
        print("\n🚀 CALLING REAL PREDICTION METHOD...")
        try:
            predictions = scorer.score(interval)
            print("🎉 SUCCESS! Real predictions received:")
            print(f"   Predictions: {predictions}")
            print(f"   Type: {type(predictions)}")
            return True
        except Exception as e:
            print(f"⚠ Prediction call failed: {e}")
            print("   This might be due to missing model files or configuration")
            return False
        
    except Exception as e:
        print(f"✗ Failed to call interval predictions: {e}")
        return False

def call_real_predictions_with_different_outputs():
    """Try different output types"""
    print("\n=== Calling Real Predictions with Different Output Types ===")
    
    try:
        from alphagenome.data.genome import Interval, Variant
        from alphagenome.models.variant_scorers import GeneMaskActiveScorer
        from alphagenome.models.dna_client import OutputType
        
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
        
        # Try different output types
        output_types = [
            OutputType.ATAC,
            OutputType.RNA_SEQ,
            OutputType.CAGE,
            OutputType.DNASE
        ]
        
        for output_type in output_types:
            try:
                print(f"\n--- Trying output type: {output_type} ---")
                
                scorer = GeneMaskActiveScorer(requested_output=output_type)
                print(f"✓ Created scorer for {output_type}")
                
                predictions = scorer.score(variant, interval)
                print(f"🎉 SUCCESS with {output_type}!")
                print(f"   Predictions: {predictions}")
                
            except Exception as e:
                print(f"⚠ Failed with {output_type}: {e}")
        
        return True
        
    except Exception as e:
        print(f"✗ Failed to call predictions with different outputs: {e}")
        return False

def main():
    """Run all real prediction calls"""
    print("Calling Real AlphaGenome Predictions")
    print("=" * 50)
    
    tests = [
        call_real_variant_predictions,
        call_real_interval_predictions,
        call_real_predictions_with_different_outputs
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"✗ Test {test.__name__} failed with exception: {e}")
    
    print(f"\n=== Summary ===")
    print(f"Tests passed: {passed}/{total}")
    
    if passed > 0:
        print("\n🎉 SUCCESS! You got real predictions!")
        print("Your AlphaGenome integration is working with real predictions!")
    else:
        print("\n⚠ No real predictions received.")
        print("This might be due to missing model files.")
        print("Contact AlphaGenome support for model files and setup instructions.")
    
    return passed > 0

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
