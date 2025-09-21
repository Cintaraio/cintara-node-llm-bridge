#!/usr/bin/env python3
"""
Script to explore Cintara node's LevelDB database structure
This helps us understand how to query transactions directly
"""

import os
import sys

def explore_cintara_database():
    """Explore the Cintara node's LevelDB database"""

    print("=== CINTARA NODE DATABASE EXPLORATION ===")

    # Database path from analysis report
    db_path = "/home/ubuntu/data/.tmp-cintarad/data/application.db"

    print(f"Database path: {db_path}")
    print(f"Database exists: {os.path.exists(db_path)}")

    if os.path.exists(db_path):
        print("\nDatabase files:")
        for file in os.listdir(db_path):
            file_path = os.path.join(db_path, file)
            size = os.path.getsize(file_path) if os.path.isfile(file_path) else 0
            print(f"  {file}: {size} bytes")

    # Try to access with different Python LevelDB libraries
    db_libraries = [
        ("plyvel", "import plyvel"),
        ("leveldb", "import leveldb"),
    ]

    print("\nChecking available LevelDB libraries:")
    available_libs = []

    for lib_name, import_stmt in db_libraries:
        try:
            exec(import_stmt)
            available_libs.append(lib_name)
            print(f"  ✅ {lib_name} - Available")
        except ImportError:
            print(f"  ❌ {lib_name} - Not available")

    if not available_libs:
        print("\n⚠️  No LevelDB libraries available. Install with:")
        print("  pip install plyvel")
        print("  # or")
        print("  pip install leveldb-python")
        return

    # Try to open and explore the database
    if "plyvel" in available_libs:
        try_plyvel_exploration(db_path)
    elif "leveldb" in available_libs:
        try_leveldb_exploration(db_path)

def try_plyvel_exploration(db_path):
    """Try to explore using plyvel library"""
    try:
        import plyvel
        print(f"\n=== EXPLORING WITH PLYVEL ===")

        # Open database in read-only mode to avoid conflicts
        db = plyvel.DB(db_path, create_if_missing=False)

        print("Database opened successfully!")

        # Sample some keys to understand the structure
        print("\nSampling database keys (first 20):")
        count = 0
        for key, value in db:
            if count >= 20:
                break

            # Decode key and show info
            key_str = key.decode('utf-8', errors='ignore')
            value_len = len(value)

            print(f"  Key: {key_str[:50]}{'...' if len(key_str) > 50 else ''}")
            print(f"       Value length: {value_len} bytes")

            # Look for transaction-related keys
            if any(keyword in key_str.lower() for keyword in ['tx', 'transaction', 'hash', 'block']):
                print(f"       ⭐ Potential transaction key!")

            count += 1

        db.close()

    except Exception as e:
        print(f"Error with plyvel: {e}")

def try_leveldb_exploration(db_path):
    """Try to explore using leveldb library"""
    try:
        import leveldb
        print(f"\n=== EXPLORING WITH LEVELDB ===")

        db = leveldb.LevelDB(db_path)
        print("Database opened successfully!")

        # Sample some keys
        print("\nSampling database keys (first 20):")
        count = 0
        for key, value in db.RangeIter():
            if count >= 20:
                break

            key_str = key.decode('utf-8', errors='ignore')
            value_len = len(value)

            print(f"  Key: {key_str[:50]}{'...' if len(key_str) > 50 else ''}")
            print(f"       Value length: {value_len} bytes")

            if any(keyword in key_str.lower() for keyword in ['tx', 'transaction', 'hash', 'block']):
                print(f"       ⭐ Potential transaction key!")

            count += 1

    except Exception as e:
        print(f"Error with leveldb: {e}")

def check_node_config():
    """Check additional node configuration details"""
    print("\n=== NODE CONFIGURATION CHECK ===")

    config_files = [
        "/home/ubuntu/data/.tmp-cintarad/config/app.toml",
        "/home/ubuntu/data/.tmp-cintarad/config/config.toml",
    ]

    for config_file in config_files:
        if os.path.exists(config_file):
            print(f"\nChecking {config_file}:")
            try:
                with open(config_file, 'r') as f:
                    content = f.read()

                # Look for database-related config
                if 'indexer' in content.lower():
                    print("  Found indexer configuration")
                if 'database' in content.lower():
                    print("  Found database configuration")
                if 'tx_index' in content.lower():
                    print("  Found tx_index configuration")

                # Show relevant lines
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if any(keyword in line.lower() for keyword in ['indexer', 'database', 'tx_index', 'postgres']):
                        print(f"    Line {i+1}: {line.strip()}")

            except Exception as e:
                print(f"  Error reading config: {e}")
        else:
            print(f"Config file not found: {config_file}")

if __name__ == "__main__":
    try:
        explore_cintara_database()
        check_node_config()
    except KeyboardInterrupt:
        print("\nExploration interrupted by user")
    except Exception as e:
        print(f"Exploration failed: {e}")
        import traceback
        traceback.print_exc()