#!/usr/bin/env python3
"""
Direct test of readonly LevelDB access
"""

def test_readonly_db():
    try:
        import plyvel
        print("✅ plyvel imported successfully")
    except ImportError as e:
        print(f"❌ plyvel import failed: {e}")
        return

    # Test paths to try
    test_paths = [
        '/data/tx_index_readonly.db',
        '/data/.tmp-cintarad/data/tx_index_readonly.db',
        '/data/tx_index.db',
        '/data/.tmp-cintarad/data/tx_index.db'
    ]

    for path in test_paths:
        print(f"\n🔍 Testing path: {path}")

        import os
        if not os.path.exists(path):
            print(f"   ❌ Path does not exist")
            continue

        print(f"   ✅ Path exists")

        # Check if it's a directory
        if not os.path.isdir(path):
            print(f"   ❌ Not a directory")
            continue

        print(f"   ✅ Is a directory")

        # List contents
        try:
            contents = os.listdir(path)
            print(f"   ✅ Contents ({len(contents)} files): {contents[:5]}")
        except Exception as e:
            print(f"   ❌ Cannot list contents: {e}")
            continue

        # Try to open with plyvel
        try:
            print(f"   🔍 Attempting to open LevelDB...")
            db = plyvel.DB(path, create_if_missing=False)
            print(f"   ✅ Successfully opened LevelDB!")

            # Try to read some data
            try:
                count = 0
                sample_keys = []
                for key, value in db:
                    sample_keys.append(key.hex()[:16])
                    count += 1
                    if count >= 5:
                        break

                print(f"   ✅ Successfully read {count} records")
                print(f"   ✅ Sample keys: {sample_keys}")

                db.close()
                print(f"   ✅ Database closed successfully")
                return True

            except Exception as e:
                print(f"   ❌ Failed to read data: {e}")
                db.close()

        except Exception as e:
            print(f"   ❌ Failed to open LevelDB: {e}")
            continue

    print(f"\n❌ Could not successfully open any LevelDB")
    return False

if __name__ == "__main__":
    test_readonly_db()