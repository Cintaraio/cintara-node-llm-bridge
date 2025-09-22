#!/usr/bin/env python3
"""
Test script to diagnose Cintara node API capabilities for transaction searching
"""

import requests
import json
import sys

def test_node_api():
    """Test various node API endpoints to understand available data"""

    node_url = "http://localhost:26657"
    test_address = "0x400d4a7c9df0b8f438e819b91f7d76b4ed27ce1c"

    print("🔍 Testing Cintara Node API Capabilities")
    print("=" * 50)

    # Test 1: Node status
    try:
        resp = requests.get(f"{node_url}/status", timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            height = data['result']['sync_info']['latest_block_height']
            print(f"✅ Node Status: Block {height}")
        else:
            print(f"❌ Node Status failed: {resp.status_code}")
            return
    except Exception as e:
        print(f"❌ Node unreachable: {e}")
        return

    # Test 2: Check what search indexes are available
    print("\n🔍 Testing transaction search capabilities:")

    search_queries = [
        "message.action='ethereum_tx'",
        "ethereum_tx.hash EXISTS",
        "tx.height > 1",
        f"message.sender='{test_address}'",
        f"ethereum_tx.from='{test_address}'",
        f"transfer.recipient='{test_address}'",
    ]

    for query in search_queries:
        try:
            search_url = f"{node_url}/tx_search"
            params = {
                'query': query,
                'prove': 'false',
                'page': '1',
                'per_page': '5',
                'order_by': 'desc'
            }

            resp = requests.get(search_url, params=params, timeout=15)
            if resp.status_code == 200:
                data = resp.json()
                total = data.get('result', {}).get('total_count', 0)
                txs = data.get('result', {}).get('txs', [])
                print(f"   Query: {query}")
                print(f"   Result: {total} total, {len(txs)} returned")

                if txs:
                    # Show sample transaction structure
                    sample_tx = txs[0]
                    print(f"   Sample TX hash: {sample_tx.get('hash', 'N/A')}")
                    events = sample_tx.get('tx_result', {}).get('events', [])
                    print(f"   Sample events: {[e.get('type') for e in events[:3]]}")
                    print()
            else:
                print(f"   Query failed: {query} - {resp.status_code}")

        except Exception as e:
            print(f"   Error with query '{query}': {e}")

    # Test 3: Get recent blocks to see transaction structure
    print("\n🔍 Analyzing recent block transactions:")

    try:
        current_height = int(height)
        for block_height in range(current_height, current_height - 5, -1):
            block_resp = requests.get(f"{node_url}/block", params={'height': str(block_height)}, timeout=10)

            if block_resp.status_code == 200:
                block_data = block_resp.json()
                txs = block_data.get('result', {}).get('block', {}).get('data', {}).get('txs', [])

                print(f"   Block {block_height}: {len(txs)} transactions")

                for i, tx_hash in enumerate(txs[:2]):  # Check first 2 transactions
                    # Get transaction details
                    tx_resp = requests.get(f"{node_url}/tx", params={'hash': tx_hash, 'prove': 'false'}, timeout=10)

                    if tx_resp.status_code == 200:
                        tx_data = tx_resp.json()
                        tx_result = tx_data.get('result', {})
                        events = tx_result.get('tx_result', {}).get('events', [])

                        print(f"     TX {i+1}: {tx_hash[:16]}...")
                        print(f"       Events: {[e.get('type') for e in events]}")

                        # Look for addresses in events
                        for event in events:
                            if event.get('type') in ['ethereum_tx', 'message', 'transfer']:
                                attrs = event.get('attributes', [])
                                for attr in attrs:
                                    key = attr.get('key', '')
                                    value = attr.get('value', '')
                                    if any(addr_key in key.lower() for addr_key in ['from', 'to', 'sender', 'recipient']):
                                        print(f"         {key}: {value}")
                    break  # Just check one transaction per block

    except Exception as e:
        print(f"   Block analysis failed: {e}")

    # Test 4: Check if there are any EVM transactions at all
    print("\n🔍 Searching for any EVM transactions:")

    try:
        # Search for any ethereum transactions
        resp = requests.get(f"{node_url}/tx_search", params={
            'query': 'message.action=\'/ethermint.evm.v1.MsgEthereumTx\'',
            'prove': 'false',
            'page': '1',
            'per_page': '10'
        }, timeout=15)

        if resp.status_code == 200:
            data = resp.json()
            total = data.get('result', {}).get('total_count', 0)
            txs = data.get('result', {}).get('txs', [])
            print(f"   Found {total} EVM transactions total")

            if txs:
                print("   Sample EVM transaction:")
                sample = txs[0]
                events = sample.get('tx_result', {}).get('events', [])

                for event in events:
                    print(f"     Event: {event.get('type')}")
                    attrs = event.get('attributes', [])
                    for attr in attrs:
                        key = attr.get('key', '')
                        value = attr.get('value', '')
                        if value and len(value) < 100:  # Only show short values
                            print(f"       {key}: {value}")
        else:
            print(f"   EVM search failed: {resp.status_code}")

    except Exception as e:
        print(f"   EVM search error: {e}")

if __name__ == "__main__":
    test_node_api()