#!/usr/bin/env python3
"""
Test script for the updated TaxBit service with database access
Run this on EC2 to verify the enhanced database integration
"""

import sys
import os
import logging
from datetime import datetime, timezone, timedelta

# Add the bridge directory to Python path
sys.path.append('/home/ubuntu/cintara-node-llm-bridge/bridge')

try:
    from taxbit_service import TaxBitService
except ImportError as e:
    print(f"Failed to import TaxBitService: {e}")
    sys.exit(1)

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def test_database_connections():
    """Test all database connection methods"""
    print("\n=== TESTING DATABASE CONNECTIONS ===")

    service = TaxBitService()

    # Test PostgreSQL connection
    print("1. Testing PostgreSQL connection...")
    pg_conn = service.get_db_connection()
    if pg_conn:
        print("   ✅ PostgreSQL connection successful")
        pg_conn.close()
    else:
        print("   ❌ PostgreSQL connection failed (expected)")

    # Test LevelDB connections
    print("\n2. Testing LevelDB connections...")

    db_types = ['tx_index', 'evm_index', 'application', 'blockstore', 'state']
    for db_type in db_types:
        print(f"   Testing {db_type}...")
        db_conn = service.get_leveldb_connection(db_type)
        if db_conn:
            print(f"   ✅ {db_type} connection successful")
            db_conn.close()
        else:
            print(f"   ❌ {db_type} connection failed")

def test_transaction_fetching():
    """Test transaction fetching with different methods"""
    print("\n=== TESTING TRANSACTION FETCHING ===")

    service = TaxBitService()

    # Test addresses from the analysis
    test_addresses = [
        "0x400d4a7c9df0b8f438e819b91f7d76b4ed27ce1c",  # Known EVM test address
        "cintara1xyz...",  # Placeholder Cosmos address
    ]

    for address in test_addresses:
        print(f"\n3. Testing transaction fetch for {address}...")

        try:
            # Test database fetching
            print("   3a. Testing database fetching...")
            db_transactions = service.fetch_transactions_from_db(address)
            print(f"      Database found {len(db_transactions)} transactions")

            # Test RPC fetching
            print("   3b. Testing RPC fetching...")
            rpc_transactions = service.fetch_transactions_by_address(address)
            print(f"      RPC found {len(rpc_transactions)} transactions")

            # Test specific known transaction
            if address == "0x400d4a7c9df0b8f438e819b91f7d76b4ed27ce1c":
                print("   3c. Testing known transaction fetch...")
                known_tx = service.fetch_transaction_by_hash("0x50cdbd6ab0fae1a7a65f556e1aa6602eb1e7b5817dea7708a5761f8a87dc36e3")
                if known_tx:
                    print("      ✅ Known transaction fetched successfully")
                    print(f"      Transaction details: {known_tx}")
                else:
                    print("      ❌ Known transaction fetch failed")

        except Exception as e:
            print(f"      ❌ Error testing {address}: {e}")
            logger.exception(f"Error testing address {address}")

def test_evm_rpc_integration():
    """Test EVM JSON-RPC integration"""
    print("\n=== TESTING EVM JSON-RPC INTEGRATION ===")

    service = TaxBitService()
    test_address = "0x400d4a7c9df0b8f438e819b91f7d76b4ed27ce1c"

    print(f"4. Testing EVM JSON-RPC for {test_address}...")

    try:
        evm_transactions = service._fetch_evm_transactions_via_rpc(test_address)
        print(f"   EVM JSON-RPC found {len(evm_transactions)} transactions")

        if evm_transactions:
            print("   Sample EVM transaction:")
            for key, value in evm_transactions[0].items():
                print(f"     {key}: {value}")

    except Exception as e:
        print(f"   ❌ EVM JSON-RPC test failed: {e}")
        logger.exception("EVM JSON-RPC test error")

def test_taxbit_export():
    """Test complete TaxBit export functionality"""
    print("\n=== TESTING TAXBIT EXPORT ===")

    service = TaxBitService()
    test_address = "0x400d4a7c9df0b8f438e819b91f7d76b4ed27ce1c"

    print(f"5. Testing TaxBit export for {test_address}...")

    try:
        # Test with date range (last 30 days)
        end_date = datetime.now(timezone.utc)
        start_date = end_date - timedelta(days=30)

        csv_output = service.export_address_transactions(
            address=test_address,
            start_date=start_date,
            end_date=end_date
        )

        lines_count = len(csv_output.split('\n'))
        print(f"   Generated CSV with {lines_count} lines")
        print("   CSV Preview (first 300 chars):")
        print(f"   {csv_output[:300]}...")

        # Save sample output
        with open('/tmp/taxbit_sample_export.csv', 'w') as f:
            f.write(csv_output)
        print("   ✅ Sample export saved to /tmp/taxbit_sample_export.csv")

    except Exception as e:
        print(f"   ❌ TaxBit export test failed: {e}")
        logger.exception("TaxBit export test error")

def test_service_status():
    """Test overall service status and configuration"""
    print("\n=== SERVICE STATUS SUMMARY ===")

    service = TaxBitService()

    print("Configuration:")
    print(f"  Node URL: {service.node_url}")
    print(f"  REST API URL: {service.rest_api_url}")
    print(f"  EVM RPC URL: {service.evm_rpc_url}")
    print(f"  LevelDB Paths: {service.leveldb_paths}")

    # Test basic connectivity
    import requests

    endpoints = [
        ("Cosmos RPC", service.node_url + "/status"),
        ("Cosmos REST", service.rest_api_url + "/cosmos/base/tendermint/v1beta1/node_info"),
        ("EVM JSON-RPC", service.evm_rpc_url),
    ]

    print("\nEndpoint Status:")
    for name, url in endpoints:
        try:
            if name == "EVM JSON-RPC":
                # POST request for JSON-RPC
                response = requests.post(url, json={"jsonrpc": "2.0", "method": "net_version", "id": 1}, timeout=5)
            else:
                response = requests.get(url, timeout=5)

            if response.status_code == 200:
                print(f"  ✅ {name}: OK")
            else:
                print(f"  ⚠️  {name}: Status {response.status_code}")
        except Exception as e:
            print(f"  ❌ {name}: {e}")

def main():
    """Run all tests"""
    print("CINTARA TAXBIT SERVICE TEST SUITE")
    print("=" * 50)

    try:
        test_database_connections()
        test_transaction_fetching()
        test_evm_rpc_integration()
        test_taxbit_export()
        test_service_status()

        print("\n" + "=" * 50)
        print("TEST SUITE COMPLETE")
        print("Check the logs above for any errors or issues.")
        print("If tests pass, the updated TaxBit service is ready for production!")

    except Exception as e:
        print(f"\nTest suite failed with error: {e}")
        logger.exception("Test suite error")
        sys.exit(1)

if __name__ == "__main__":
    main()