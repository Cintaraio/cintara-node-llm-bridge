#!/usr/bin/env python3
"""
EC2 Database Analysis Script for Cintara Node
Run this on the EC2 instance to understand database configuration and options
"""

import os
import sys
import subprocess
import json
import requests
from pathlib import Path

def run_command(cmd):
    """Run a shell command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", "Command timed out", 1
    except Exception as e:
        return "", str(e), 1

def check_node_status():
    """Check if Cintara node is running and accessible"""
    print("=== CINTARA NODE STATUS ===")

    # Check if process is running
    stdout, stderr, code = run_command("ps aux | grep cintarad | grep -v grep")
    if stdout:
        print("✅ Cintarad process is running:")
        for line in stdout.split('\n'):
            if 'cintarad' in line:
                print(f"  {line}")
    else:
        print("❌ Cintarad process not found")

    # Check RPC status
    try:
        response = requests.get("http://localhost:26657/status", timeout=5)
        if response.status_code == 200:
            status = response.json()
            print("✅ RPC endpoint responding")
            print(f"  Latest block: {status['result']['sync_info']['latest_block_height']}")
            print(f"  Network: {status['result']['node_info']['network']}")
            print(f"  TX Index: {status['result']['node_info']['other'].get('tx_index', 'unknown')}")
        else:
            print(f"❌ RPC endpoint error: {response.status_code}")
    except Exception as e:
        print(f"❌ RPC endpoint not accessible: {e}")

def find_database_locations():
    """Find all potential database locations"""
    print("\n=== DATABASE LOCATION DISCOVERY ===")

    # Common database paths
    search_paths = [
        "/home/ubuntu/data",
        "/home/ubuntu/.cintarad",
        "/root/.cintarad",
        "/data",
        "/var/lib/cintara",
        "/opt/cintara"
    ]

    db_locations = []

    for search_path in search_paths:
        if os.path.exists(search_path):
            print(f"Searching in {search_path}...")
            stdout, stderr, code = run_command(f"find {search_path} -name '*.db' -type d 2>/dev/null")
            if stdout:
                for db_path in stdout.split('\n'):
                    if db_path.strip():
                        db_locations.append(db_path.strip())
                        size_out, _, _ = run_command(f"du -sh '{db_path}' 2>/dev/null")
                        print(f"  Found: {db_path} ({size_out.split()[0] if size_out else 'unknown size'})")

    return db_locations

def check_postgresql():
    """Check PostgreSQL availability and configuration"""
    print("\n=== POSTGRESQL CHECK ===")

    # Check if PostgreSQL is installed
    stdout, stderr, code = run_command("which psql")
    if code == 0:
        print("✅ PostgreSQL client available")

        # Check if server is running
        stdout, stderr, code = run_command("systemctl is-active postgresql")
        if code == 0 and stdout == "active":
            print("✅ PostgreSQL server is running")

            # Try to connect and list databases
            stdout, stderr, code = run_command("sudo -u postgres psql -l")
            if code == 0:
                print("✅ Can connect to PostgreSQL")
                print("Available databases:")
                for line in stdout.split('\n')[3:]:  # Skip header
                    if '|' in line and line.strip():
                        db_name = line.split('|')[0].strip()
                        if db_name and not db_name.startswith('-'):
                            print(f"  - {db_name}")
            else:
                print(f"❌ Cannot connect to PostgreSQL: {stderr}")
        else:
            print("❌ PostgreSQL server not running")
    else:
        print("❌ PostgreSQL not installed")

def analyze_node_config():
    """Analyze node configuration files"""
    print("\n=== NODE CONFIGURATION ANALYSIS ===")

    # Find config directories
    config_paths = []
    stdout, stderr, code = run_command("find /home /data /root -name 'app.toml' -o -name 'config.toml' 2>/dev/null")
    if stdout:
        config_paths = stdout.split('\n')

    for config_path in config_paths:
        if not config_path.strip():
            continue

        print(f"\nAnalyzing: {config_path}")

        if os.path.exists(config_path):
            try:
                with open(config_path, 'r') as f:
                    content = f.read()

                # Check for database-related configuration
                key_configs = {
                    'indexer': ['indexer =', 'enable-indexer', 'tx-index'],
                    'database': ['database', 'db-backend', 'db-dir'],
                    'postgresql': ['psql', 'postgres', 'pg_'],
                    'evm': ['[evm]', 'enable-indexer', 'json-rpc'],
                    'api': ['[api]', 'enable =', 'address =']
                }

                for category, keywords in key_configs.items():
                    matching_lines = []
                    for i, line in enumerate(content.split('\n'), 1):
                        if any(keyword.lower() in line.lower() for keyword in keywords):
                            matching_lines.append(f"    Line {i}: {line.strip()}")

                    if matching_lines:
                        print(f"  {category.upper()} configuration:")
                        for line in matching_lines[:5]:  # Limit to 5 lines per category
                            print(line)
                        if len(matching_lines) > 5:
                            print(f"    ... and {len(matching_lines) - 5} more lines")

            except Exception as e:
                print(f"  Error reading config: {e}")

def check_indexer_status():
    """Check transaction indexer status and configuration"""
    print("\n=== TRANSACTION INDEXER STATUS ===")

    # Check indexer through RPC
    try:
        # Try to get a recent transaction
        response = requests.get("http://localhost:26657/tx_search?query=\"tx.height>1000000\"&per_page=1", timeout=10)
        if response.status_code == 200:
            data = response.json()
            total_count = data.get('result', {}).get('total_count', 0)
            print(f"✅ Transaction indexer responding, {total_count} transactions found")

            if data.get('result', {}).get('txs'):
                tx = data['result']['txs'][0]
                print(f"  Sample transaction: {tx.get('hash', 'unknown')[:16]}...")
                print(f"  Block height: {tx.get('height', 'unknown')}")
        else:
            print(f"❌ Transaction search failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Transaction indexer check failed: {e}")

    # Check EVM indexer
    try:
        response = requests.get("http://localhost:8545", timeout=5)
        print("✅ EVM JSON-RPC endpoint responding")
    except:
        print("❌ EVM JSON-RPC endpoint not accessible (port 8545)")

def test_database_libraries():
    """Test availability of database libraries"""
    print("\n=== PYTHON DATABASE LIBRARIES ===")

    libraries = [
        ('plyvel', 'LevelDB access'),
        ('psycopg2', 'PostgreSQL access'),
        ('sqlite3', 'SQLite access (built-in)'),
        ('requests', 'HTTP requests (for RPC)')
    ]

    available_libs = []

    for lib_name, description in libraries:
        try:
            __import__(lib_name)
            print(f"✅ {lib_name} - {description}")
            available_libs.append(lib_name)
        except ImportError:
            print(f"❌ {lib_name} - {description} (not available)")

    return available_libs

def generate_recommendations(db_locations, available_libs):
    """Generate recommendations based on findings"""
    print("\n=== RECOMMENDATIONS ===")

    if not db_locations:
        print("❌ No LevelDB databases found - node may not be storing data locally")
        print("   Recommendation: Continue with RPC-based approach")
        return

    if 'plyvel' in available_libs:
        print("✅ LevelDB access possible with plyvel")
        print("   Next step: Install plyvel and explore database structure")
        print("   Command: pip3 install plyvel")
    else:
        print("⚠️  LevelDB libraries not available")
        print("   Install command: pip3 install plyvel")

    if 'psycopg2' in available_libs:
        print("✅ PostgreSQL access available")
        print("   Check if node is configured to use PostgreSQL indexer")
    else:
        print("⚠️  PostgreSQL library not available")
        print("   Install command: pip3 install psycopg2-binary")

    print("\n📋 IMPLEMENTATION OPTIONS:")
    print("1. Enable EVM indexer and restart node (requires downtime)")
    print("2. Set up PostgreSQL indexer for better transaction querying")
    print("3. Use LevelDB direct access (requires plyvel installation)")
    print("4. Continue with enhanced RPC parsing (current approach)")
    print("5. Integrate with testnet.cintara.io portal logic")

def main():
    """Main analysis function"""
    print("CINTARA NODE DATABASE ANALYSIS")
    print("=" * 50)

    check_node_status()
    db_locations = find_database_locations()
    check_postgresql()
    analyze_node_config()
    check_indexer_status()
    available_libs = test_database_libraries()
    generate_recommendations(db_locations, available_libs)

    print(f"\nAnalysis complete. Found {len(db_locations)} database location(s).")
    if db_locations:
        print("Database locations:")
        for loc in db_locations:
            print(f"  - {loc}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nAnalysis interrupted by user")
    except Exception as e:
        print(f"Analysis failed: {e}")
        import traceback
        traceback.print_exc()