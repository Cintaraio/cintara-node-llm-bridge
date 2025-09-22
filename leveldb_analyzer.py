#!/usr/bin/env python3
"""
Advanced LevelDB Analyzer for Cintara Transaction Database
Decode the key-value structure and extract transaction data
"""

import sys
import os
import json
import base64
import hashlib
from typing import Dict, List, Any, Optional
import struct

# Add bridge directory for imports
sys.path.append('/home/ubuntu/cintara-node-llm-bridge/bridge')

try:
    import plyvel
    PLYVEL_AVAILABLE = True
except ImportError:
    print("Error: plyvel not available. Install with: pip3 install plyvel")
    sys.exit(1)

class LevelDBAnalyzer:
    """Advanced analyzer for Cintara LevelDB structure"""

    def __init__(self):
        self.db_paths = {
            'tx_index': '/data/.tmp-cintarad/data/tx_index.db',
            'evm_index': '/data/.tmp-cintarad/data/evmindexer.db',
            'application': '/data/.tmp-cintarad/data/application.db',
            'blockstore': '/data/.tmp-cintarad/data/blockstore.db',
            'state': '/data/.tmp-cintarad/data/state.db'
        }

    def open_database(self, db_name: str):
        """Open LevelDB database safely"""
        db_path = self.db_paths.get(db_name)
        if not db_path or not os.path.exists(db_path):
            print(f"Database not found: {db_name} at {db_path}")
            return None

        try:
            return plyvel.DB(db_path, create_if_missing=False)
        except Exception as e:
            print(f"Failed to open {db_name}: {e}")
            return None

    def analyze_key_patterns(self, db_name: str, sample_count: int = 100):
        """Analyze key patterns to understand database structure"""
        print(f"\n=== ANALYZING {db_name.upper()} KEY PATTERNS ===")

        db = self.open_database(db_name)
        if not db:
            return

        try:
            key_patterns = {}
            sample_keys = []

            count = 0
            for key, value in db:
                if count >= sample_count:
                    break

                # Analyze key structure
                key_info = self._analyze_key(key, value)
                sample_keys.append(key_info)

                # Categorize by length and pattern
                key_len = len(key)
                if key_len not in key_patterns:
                    key_patterns[key_len] = []
                key_patterns[key_len].append(key_info)

                count += 1

            # Print analysis
            print(f"Analyzed {count} keys from {db_name}")
            print(f"Key length distribution:")

            for length, keys in sorted(key_patterns.items()):
                print(f"  Length {length}: {len(keys)} keys")
                if len(keys) <= 3:  # Show details for small groups
                    for key_info in keys:
                        print(f"    {key_info}")

            # Look for transaction-related patterns
            self._identify_transaction_keys(sample_keys, db_name)

        finally:
            db.close()

    def _analyze_key(self, key: bytes, value: bytes) -> Dict[str, Any]:
        """Analyze individual key structure"""
        key_hex = key.hex()
        key_ascii = key.decode('utf-8', errors='ignore')

        # Try to identify key type
        key_type = self._identify_key_type(key, value)

        return {
            'length': len(key),
            'hex': key_hex[:40] + ('...' if len(key_hex) > 40 else ''),
            'ascii': key_ascii[:40] + ('...' if len(key_ascii) > 40 else ''),
            'value_size': len(value),
            'type': key_type
        }

    def _identify_key_type(self, key: bytes, value: bytes) -> str:
        """Try to identify what type of key this is"""
        key_hex = key.hex()

        # Common patterns in Cosmos SDK databases
        if len(key) == 32:
            return "hash_32"
        elif len(key) == 20:
            return "address_20"
        elif len(key) == 1:
            return "prefix_1"
        elif key.startswith(b'tx:'):
            return "tx_prefix"
        elif key.startswith(b'block:'):
            return "block_prefix"
        elif b'height' in key:
            return "height_related"
        elif len(key) > 32 and len(key) < 64:
            return "compound_key"
        else:
            return f"unknown_{len(key)}"

    def _identify_transaction_keys(self, sample_keys: List[Dict], db_name: str):
        """Identify keys that likely contain transaction data"""
        print(f"\nTransaction-related keys in {db_name}:")

        tx_candidates = []
        for key_info in sample_keys:
            if (key_info['type'] in ['hash_32', 'compound_key'] and
                key_info['value_size'] > 1000):  # Large values likely contain transaction data
                tx_candidates.append(key_info)

        print(f"Found {len(tx_candidates)} potential transaction keys")
        for candidate in tx_candidates[:5]:  # Show first 5
            print(f"  {candidate}")

    def explore_transaction_structure(self, target_address: str = "0x400d4a7c9df0b8f438e819b91f7d76b4ed27ce1c"):
        """Deep dive into transaction structure with specific address"""
        print(f"\n=== EXPLORING TRANSACTION STRUCTURE FOR {target_address} ===")

        # Try tx_index database
        db = self.open_database('tx_index')
        if not db:
            return

        try:
            address_lower = target_address.lower()
            address_bytes = bytes.fromhex(target_address[2:]) if target_address.startswith('0x') else target_address.encode()

            found_keys = []
            scanned = 0

            print("Scanning for address-related keys...")

            for key, value in db:
                scanned += 1

                # Multiple search strategies
                if (address_lower in key.hex().lower() or
                    address_bytes in key or
                    address_bytes in value[:200]):  # Check first 200 bytes of value

                    print(f"\n🎯 FOUND MATCH #{len(found_keys) + 1}")
                    print(f"Key (hex): {key.hex()}")
                    print(f"Key (ascii): {key.decode('utf-8', errors='ignore')}")
                    print(f"Value size: {len(value)} bytes")

                    # Try to decode value
                    decoded_data = self._decode_transaction_value(value)
                    if decoded_data:
                        print(f"Decoded transaction data:")
                        for field, data in decoded_data.items():
                            print(f"  {field}: {data}")

                    found_keys.append((key, value))

                    if len(found_keys) >= 3:  # Limit to avoid too much output
                        break

                if scanned >= 2000:  # Limit scan to avoid timeout
                    break

            print(f"\nScanned {scanned} keys, found {len(found_keys)} matches")

        finally:
            db.close()

    def _decode_transaction_value(self, value: bytes) -> Optional[Dict[str, Any]]:
        """Try to decode transaction value using multiple strategies"""
        decoded = {}

        # Strategy 1: Try as JSON
        try:
            value_str = value.decode('utf-8')
            if value_str.startswith('{'):
                json_data = json.loads(value_str)
                decoded['json'] = json_data
                return decoded
        except:
            pass

        # Strategy 2: Look for protobuf patterns
        try:
            # Common protobuf field patterns
            if b'MsgEthereumTx' in value:
                decoded['type'] = 'MsgEthereumTx'
            if b'MsgSend' in value:
                decoded['type'] = 'MsgSend'
            if b'withdraw' in value:
                decoded['type'] = 'withdraw_related'

            # Look for hex addresses in value
            value_hex = value.hex()
            # EVM address pattern (40 hex chars)
            import re
            addresses = re.findall(r'[0-9a-fA-F]{40}', value_hex)
            if addresses:
                decoded['found_addresses'] = [f"0x{addr}" for addr in addresses[:3]]

            # Look for amounts (common uint64 patterns)
            amounts = self._extract_amounts_from_bytes(value)
            if amounts:
                decoded['found_amounts'] = amounts[:3]

        except Exception as e:
            decoded['decode_error'] = str(e)

        return decoded if decoded else None

    def _extract_amounts_from_bytes(self, data: bytes) -> List[str]:
        """Extract potential amount values from raw bytes"""
        amounts = []

        # Look for 8-byte uint64 patterns that could be amounts
        for i in range(0, len(data) - 8, 1):
            try:
                # Try big-endian and little-endian
                amount_be = struct.unpack('>Q', data[i:i+8])[0]
                amount_le = struct.unpack('<Q', data[i:i+8])[0]

                # Filter for reasonable amounts (1 wei to 1000 tokens)
                for amount in [amount_be, amount_le]:
                    if 1 <= amount <= 1000 * 10**18:
                        amounts.append(str(amount))

                if len(amounts) >= 10:  # Limit results
                    break

            except:
                continue

        return list(set(amounts))  # Remove duplicates

    def extract_recent_transactions(self, limit: int = 20):
        """Extract recent transactions with full details"""
        print(f"\n=== EXTRACTING RECENT TRANSACTIONS (LIMIT: {limit}) ===")

        db = self.open_database('tx_index')
        if not db:
            return []

        try:
            transactions = []

            # In Cosmos SDK, tx_index often stores by height or hash
            # Try to get transactions with large values (likely complete tx data)

            for key, value in db:
                if len(value) > 2000:  # Large values likely contain full transaction data
                    tx_data = self._parse_full_transaction(key, value)
                    if tx_data:
                        transactions.append(tx_data)
                        print(f"\n📄 TRANSACTION #{len(transactions)}")
                        print(f"Key: {key.hex()[:32]}...")
                        print(f"Hash: {tx_data.get('hash', 'unknown')}")
                        print(f"Type: {tx_data.get('type', 'unknown')}")
                        print(f"From: {tx_data.get('from_address', 'unknown')}")
                        print(f"To: {tx_data.get('to_address', 'unknown')}")
                        print(f"Amount: {tx_data.get('amount', '0')}")

                        if len(transactions) >= limit:
                            break

            print(f"\nExtracted {len(transactions)} transactions")
            return transactions

        finally:
            db.close()

    def _parse_full_transaction(self, key: bytes, value: bytes) -> Optional[Dict[str, Any]]:
        """Parse complete transaction from LevelDB value"""
        try:
            # Create transaction hash from key or value
            tx_hash = hashlib.sha256(key).hexdigest()

            tx_data = {
                'hash': f"0x{tx_hash[:64]}",
                'key_hex': key.hex(),
                'raw_size': len(value),
                'type': 'LevelDB',
                'from_address': '',
                'to_address': '',
                'amount': '0',
                'timestamp': '',
                'success': True
            }

            # Try to extract meaningful data
            decoded = self._decode_transaction_value(value)
            if decoded:
                tx_data.update(decoded)

                # Extract addresses if found
                if 'found_addresses' in decoded:
                    addresses = decoded['found_addresses']
                    if len(addresses) >= 2:
                        tx_data['from_address'] = addresses[0]
                        tx_data['to_address'] = addresses[1]
                    elif len(addresses) == 1:
                        tx_data['to_address'] = addresses[0]

                # Extract amounts if found
                if 'found_amounts' in decoded:
                    amounts = decoded['found_amounts']
                    if amounts:
                        tx_data['amount'] = amounts[0]

            return tx_data

        except Exception as e:
            print(f"Failed to parse transaction: {e}")
            return None

def main():
    """Run comprehensive LevelDB analysis"""
    print("CINTARA LEVELDB ADVANCED ANALYZER")
    print("=" * 50)

    analyzer = LevelDBAnalyzer()

    # Analyze key patterns for each database
    databases = ['tx_index', 'evm_index', 'blockstore']

    for db_name in databases:
        analyzer.analyze_key_patterns(db_name, sample_count=50)

    # Deep dive into transaction structure
    analyzer.explore_transaction_structure("0x400d4a7c9df0b8f438e819b91f7d76b4ed27ce1c")

    # Extract recent transactions
    transactions = analyzer.extract_recent_transactions(limit=10)

    # Save results
    output_file = "/tmp/leveldb_analysis_results.json"
    with open(output_file, 'w') as f:
        json.dump({
            'analysis_summary': 'LevelDB structure analysis complete',
            'databases_analyzed': databases,
            'extracted_transactions': transactions
        }, f, indent=2)

    print(f"\n✅ Analysis complete! Results saved to {output_file}")
    print("This analysis will help improve transaction extraction accuracy.")

if __name__ == "__main__":
    main()