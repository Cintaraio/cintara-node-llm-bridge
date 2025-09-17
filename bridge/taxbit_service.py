"""
TaxBit Integration Service for Cintara Blockchain

This module provides functionality to export Cintara blockchain transaction data
in TaxBit's required CSV format for tax reporting purposes.

TaxBit CSV Format:
timestamp, txid, source_name, from_wallet_address, to_wallet_address, category,
in_currency, in_amount, in_currency_fiat, in_amount_fiat, out_currency, out_amount,
out_currency_fiat, out_amount_fiat, fee_currency, fee, fee_currency_fiat, fee_fiat,
memo, status
"""

import csv
import io
import logging
import requests
import base64
import json
from datetime import datetime, timezone, timedelta
from typing import List, Dict, Any, Optional
from enum import Enum

logger = logging.getLogger(__name__)

class TaxBitCategory(Enum):
    """TaxBit transaction categories"""
    # Inbound categories (assets received)
    INBOUND_BUY = "Inbound > Buy"
    INBOUND_INCOME = "Inbound > Income" 
    INBOUND_AIRDROP = "Inbound > Airdrop"
    INBOUND_STAKING_REWARD = "Inbound > Staking Reward"
    INBOUND_STAKING_WITHDRAWAL = "Inbound > Staking Withdrawal"
    
    # Outbound categories (assets disposed)
    OUTBOUND_SELL = "Outbound > Sell"
    OUTBOUND_EXPENSE = "Outbound > Expense"
    OUTBOUND_FEE = "Outbound > Fee"
    OUTBOUND_STAKING_DEPOSIT = "Outbound > Staking Deposit"
    OUTBOUND_TRANSFER = "Outbound > Transfer"
    
    # Swap categories (asset exchange)
    SWAP_SWAP = "Swap > Swap"
    
    # Internal categories (between own wallets)
    INTERNAL_TRANSFER = "Internal Transfer"
    
    # Ignore category
    IGNORE = "Ignore"

class TaxBitTransaction:
    """Represents a single transaction in TaxBit format"""
    
    def __init__(self):
        self.timestamp: Optional[str] = None
        self.txid: Optional[str] = None
        self.source_name: str = "Cintara"
        self.from_wallet_address: Optional[str] = None
        self.to_wallet_address: Optional[str] = None
        self.category: Optional[str] = None
        self.in_currency: Optional[str] = None
        self.in_amount: Optional[float] = None
        self.in_currency_fiat: Optional[str] = None
        self.in_amount_fiat: Optional[float] = None
        self.out_currency: Optional[str] = None
        self.out_amount: Optional[float] = None
        self.out_currency_fiat: Optional[str] = None
        self.out_amount_fiat: Optional[float] = None
        self.fee_currency: Optional[str] = None
        self.fee: Optional[float] = None
        self.fee_currency_fiat: Optional[str] = None
        self.fee_fiat: Optional[float] = None
        self.memo: Optional[str] = None
        self.status: str = "Completed"
        
    def to_dict(self) -> Dict[str, Any]:
        """Convert transaction to dictionary format"""
        return {
            'timestamp': self.timestamp,
            'txid': self.txid,
            'source_name': self.source_name,
            'from_wallet_address': self.from_wallet_address,
            'to_wallet_address': self.to_wallet_address,
            'category': self.category,
            'in_currency': self.in_currency,
            'in_amount': self.in_amount,
            'in_currency_fiat': self.in_currency_fiat,
            'in_amount_fiat': self.in_amount_fiat,
            'out_currency': self.out_currency,
            'out_amount': self.out_amount,
            'out_currency_fiat': self.out_currency_fiat,
            'out_amount_fiat': self.out_amount_fiat,
            'fee_currency': self.fee_currency,
            'fee': self.fee,
            'fee_currency_fiat': self.fee_currency_fiat,
            'fee_fiat': self.fee_fiat,
            'memo': self.memo,
            'status': self.status
        }

class TaxBitService:
    """Service for converting Cintara transactions to TaxBit format"""

    TAXBIT_CSV_HEADERS = [
        'timestamp', 'txid', 'source_name', 'from_wallet_address', 'to_wallet_address',
        'category', 'in_currency', 'in_amount', 'in_currency_fiat', 'in_amount_fiat',
        'out_currency', 'out_amount', 'out_currency_fiat', 'out_amount_fiat',
        'fee_currency', 'fee', 'fee_currency_fiat', 'fee_fiat', 'memo', 'status'
    ]

    def __init__(self, node_url: str = "http://localhost:26657"):
        self.native_currency = "CTR"  # Cintara native token
        self.node_url = node_url
        
    def classify_transaction(self, tx_data: Dict[str, Any]) -> TaxBitCategory:
        """
        Classify transaction based on its characteristics
        
        Args:
            tx_data: Raw transaction data from indexer
            
        Returns:
            TaxBitCategory enum value
        """
        # Extract transaction type and events
        tx_type = tx_data.get('type', '')
        events = tx_data.get('events', [])
        
        # Check for staking-related transactions
        if 'MsgDelegate' in tx_type:
            return TaxBitCategory.OUTBOUND_STAKING_DEPOSIT
        elif 'MsgWithdrawDelegatorReward' in tx_type:
            return TaxBitCategory.INBOUND_STAKING_REWARD
        elif 'MsgUndelegate' in tx_type:
            return TaxBitCategory.INBOUND_STAKING_WITHDRAWAL
            
        # Check for transfers
        if 'MsgSend' in tx_type or 'transfer' in tx_type.lower():
            # For now, classify as outbound transfer
            # TODO: Add logic to detect internal transfers
            return TaxBitCategory.OUTBOUND_TRANSFER
            
        # Check for EVM transactions
        if 'MsgEthereumTx' in tx_type:
            # TODO: Parse EVM events to determine if it's a swap, transfer, etc.
            return TaxBitCategory.OUTBOUND_TRANSFER
            
        # Default classification
        logger.warning(f"Unknown transaction type: {tx_type}, defaulting to Transfer")
        return TaxBitCategory.OUTBOUND_TRANSFER
    
    def convert_amount(self, amount_str: str, denom: str) -> tuple[float, str]:
        """
        Convert amount from blockchain format to human-readable format
        
        Args:
            amount_str: Amount as string (e.g., "1000000")
            denom: Denomination (e.g., "uCTR")
            
        Returns:
            Tuple of (converted_amount, currency_symbol)
        """
        try:
            amount = float(amount_str)
            
            # Handle Cosmos native denominations
            if denom.startswith('u'):
                # Micro denomination (1 CTR = 1,000,000 uCTR)
                return amount / 1_000_000, denom[1:].upper()
            elif denom.startswith('a'):
                # Atto denomination (1 CTR = 1e18 aCTR)
                return amount / 1e18, denom[1:].upper()
            else:
                # Assume base denomination
                return amount, denom.upper()
                
        except ValueError:
            logger.error(f"Failed to convert amount: {amount_str}")
            return 0.0, denom.upper()
    
    def format_timestamp(self, timestamp: datetime) -> str:
        """Format timestamp in ISO 8601 UTC format for TaxBit"""
        if timestamp.tzinfo is None:
            timestamp = timestamp.replace(tzinfo=timezone.utc)
        return timestamp.isoformat().replace('+00:00', 'Z')
    
    def convert_transaction(self, tx_data: Dict[str, Any]) -> TaxBitTransaction:
        """
        Convert a single Cintara transaction to TaxBit format
        
        Args:
            tx_data: Raw transaction data from indexer
            
        Returns:
            TaxBitTransaction object
        """
        taxbit_tx = TaxBitTransaction()
        
        # Basic fields
        taxbit_tx.txid = tx_data.get('hash', tx_data.get('tx_hash'))
        
        # Format timestamp
        timestamp = tx_data.get('timestamp')
        if timestamp:
            if isinstance(timestamp, str):
                timestamp = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            taxbit_tx.timestamp = self.format_timestamp(timestamp)
        
        # Addresses
        taxbit_tx.from_wallet_address = tx_data.get('from_address')
        taxbit_tx.to_wallet_address = tx_data.get('to_address')
        
        # Classify transaction
        category = self.classify_transaction(tx_data)
        taxbit_tx.category = category.value
        
        # Handle amounts based on category
        amount = tx_data.get('amount', '0')
        denom = tx_data.get('denom', self.native_currency.lower())
        
        if amount and amount != '0':
            converted_amount, currency = self.convert_amount(str(amount), denom)
            
            # Assign to in/out based on category
            if category.value.startswith('Inbound'):
                taxbit_tx.in_currency = currency
                taxbit_tx.in_amount = converted_amount
            elif category.value.startswith('Outbound'):
                taxbit_tx.out_currency = currency
                taxbit_tx.out_amount = converted_amount
            elif category.value.startswith('Swap'):
                # For swaps, we need both in and out amounts
                # TODO: Parse swap events to get both assets
                taxbit_tx.out_currency = currency
                taxbit_tx.out_amount = converted_amount
        
        # Handle transaction fees
        fee = tx_data.get('fee', tx_data.get('gas_fee'))
        if fee and fee != '0':
            fee_amount, fee_currency = self.convert_amount(str(fee), self.native_currency.lower())
            taxbit_tx.fee_currency = fee_currency
            taxbit_tx.fee = fee_amount
        
        # Add memo
        taxbit_tx.memo = tx_data.get('memo', '')
        
        # Status
        taxbit_tx.status = "Completed" if tx_data.get('success', True) else "Failed"
        
        return taxbit_tx
    
    def generate_csv(self, transactions: List[TaxBitTransaction]) -> str:
        """
        Generate CSV string from list of TaxBit transactions
        
        Args:
            transactions: List of TaxBitTransaction objects
            
        Returns:
            CSV string ready for download
        """
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=self.TAXBIT_CSV_HEADERS)
        
        # Write header
        writer.writeheader()
        
        # Write transactions
        for tx in transactions:
            writer.writerow(tx.to_dict())
        
        return output.getvalue()
    
    def export_address_transactions(self, address: str, start_date: Optional[datetime] = None,
                                  end_date: Optional[datetime] = None) -> str:
        """
        Export all transactions for a specific address in TaxBit CSV format

        Args:
            address: Cintara wallet address
            start_date: Optional start date for filtering
            end_date: Optional end date for filtering

        Returns:
            CSV string ready for download
        """
        logger.info(f"Fetching transactions for address: {address}")

        # Fetch real transactions from Cintara node
        transactions = self.fetch_transactions_by_address(address, start_date, end_date)

        if not transactions:
            logger.warning(f"No transactions found for address: {address}")
            # Return empty CSV with headers
            return self.generate_csv([])

        logger.info(f"Found {len(transactions)} transactions for address: {address}")

        # Convert transactions to TaxBit format
        taxbit_transactions = []
        for tx_data in transactions:
            try:
                taxbit_tx = self.convert_transaction(tx_data)
                taxbit_transactions.append(taxbit_tx)
            except Exception as e:
                logger.error(f"Failed to convert transaction {tx_data.get('hash')}: {e}")

        logger.info(f"Successfully converted {len(taxbit_transactions)} transactions to TaxBit format")

        # Generate CSV
        return self.generate_csv(taxbit_transactions)

    def fetch_transactions_by_address(self, address: str, start_date: Optional[datetime] = None,
                                    end_date: Optional[datetime] = None) -> List[Dict[str, Any]]:
        """
        Fetch transactions for a specific address from Cintara node

        Args:
            address: Cintara wallet address
            start_date: Optional start date for filtering
            end_date: Optional end date for filtering

        Returns:
            List of transaction data dictionaries
        """
        transactions = []

        try:
            # Check if node has transaction indexing enabled and any transactions exist
            logger.info(f"Fetching real transactions for address: {address}")

            # First check if there are any transactions at all in recent blocks
            try:
                status_resp = requests.get(f"{self.node_url}/status", timeout=10)
                if status_resp.status_code == 200:
                    latest_height = int(status_resp.json()['result']['sync_info']['latest_block_height'])
                    logger.info(f"Latest block height: {latest_height}")

                    # Check last 10 blocks for any transactions
                    has_transactions = False
                    for height in range(max(1, latest_height - 10), latest_height + 1):
                        block_resp = requests.get(f"{self.node_url}/block?height={height}", timeout=5)
                        if block_resp.status_code == 200:
                            txs = block_resp.json()['result']['block']['data']['txs']
                            if txs:
                                has_transactions = True
                                logger.info(f"Found {len(txs)} transactions in block {height}")
                                break

                    if not has_transactions:
                        logger.warning("No transactions found in recent blocks")
                        return []

            except Exception as e:
                logger.error(f"Failed to check for transactions: {e}")
                return []

            # Try different approaches for transaction fetching based on address type
            if address.startswith('0x'):
                # Ethereum address - try EVM-specific queries
                transactions.extend(self._fetch_evm_transactions(address))
            else:
                # Cosmos address - try standard Cosmos queries
                transactions.extend(self._fetch_cosmos_transactions(address))

            # Remove duplicates and sort by timestamp
            seen_hashes = set()
            unique_transactions = []
            for tx in transactions:
                if tx['hash'] not in seen_hashes:
                    seen_hashes.add(tx['hash'])
                    unique_transactions.append(tx)

            # Sort by timestamp descending (newest first)
            unique_transactions.sort(key=lambda x: x.get('timestamp', ''), reverse=True)

            # Apply date filtering if provided
            if start_date or end_date:
                filtered_transactions = []
                for tx in unique_transactions:
                    tx_time = datetime.fromisoformat(tx['timestamp'].replace('Z', '+00:00'))
                    if start_date and tx_time < start_date:
                        continue
                    if end_date and tx_time > end_date:
                        continue
                    filtered_transactions.append(tx)
                return filtered_transactions

            return unique_transactions

        except Exception as e:
            logger.error(f"Failed to fetch transactions for {address}: {e}")
            return []

    def _fetch_cosmos_transactions(self, address: str) -> List[Dict[str, Any]]:
        """Fetch transactions for Cosmos bech32 addresses"""
        transactions = []

        try:
            # Try different query formats
            query_formats = [
                f'transfer.recipient=\'{address}\'',
                f'transfer.sender=\'{address}\'',
                f'message.sender=\'{address}\'',
            ]

            for query in query_formats:
                try:
                    params = {'query': query, 'order_by': 'desc', 'per_page': '50'}
                    resp = requests.get(f"{self.node_url}/tx_search", params=params, timeout=30)

                    if resp.status_code == 200:
                        data = resp.json()
                        if 'result' in data and 'txs' in data['result']:
                            transactions.extend(self._parse_cosmos_transactions(data['result']['txs'], address))
                            logger.info(f"Found {len(data['result']['txs'])} transactions with query: {query}")

                except Exception as e:
                    logger.warning(f"Query failed for {query}: {e}")
                    continue

        except Exception as e:
            logger.error(f"Failed to fetch Cosmos transactions: {e}")

        return transactions

    def _fetch_evm_transactions(self, address: str) -> List[Dict[str, Any]]:
        """Fetch transactions for Ethereum addresses (0x...)"""
        transactions = []

        try:
            # For EVM addresses, try different approaches
            logger.info(f"Attempting to fetch EVM transactions for {address}")

            # Try searching for EVM transactions
            query_formats = [
                f'ethereum_tx.from=\'{address}\'',
                f'ethereum_tx.to=\'{address}\'',
                f'message.action=\'/ethermint.evm.v1.MsgEthereumTx\'',
            ]

            for query in query_formats:
                try:
                    params = {'query': query, 'order_by': 'desc', 'per_page': '50'}
                    resp = requests.get(f"{self.node_url}/tx_search", params=params, timeout=30)

                    if resp.status_code == 200:
                        data = resp.json()
                        if 'result' in data and 'txs' in data['result']:
                            # Parse EVM transactions differently
                            evm_txs = self._parse_evm_transactions(data['result']['txs'], address)
                            transactions.extend(evm_txs)
                            logger.info(f"Found {len(evm_txs)} EVM transactions with query: {query}")

                except Exception as e:
                    logger.warning(f"EVM query failed for {query}: {e}")
                    continue

        except Exception as e:
            logger.error(f"Failed to fetch EVM transactions: {e}")

        return transactions

    def _parse_evm_transactions(self, cosmos_txs: List[Dict], user_address: str) -> List[Dict[str, Any]]:
        """Parse EVM transactions from Cosmos transaction format"""
        parsed_transactions = []

        for cosmos_tx in cosmos_txs:
            try:
                tx_hash = cosmos_tx.get('hash', '')
                tx_height = cosmos_tx.get('height', '0')
                tx_result = cosmos_tx.get('tx_result', {})

                timestamp = self._get_block_timestamp(tx_height)

                # For EVM transactions, we need to decode the transaction data
                # This is a simplified version - in production you'd need full EVM log parsing
                tx_info = {
                    'hash': tx_hash,
                    'height': tx_height,
                    'timestamp': timestamp,
                    'success': tx_result.get('code', 1) == 0,
                    'type': 'MsgEthereumTx',
                    'from_address': user_address,
                    'to_address': '',  # Would need to decode from EVM transaction
                    'amount': '0',  # Would need to decode from EVM logs
                    'denom': 'uctr',
                    'fee': tx_result.get('gas_used', '0'),
                    'memo': 'EVM Transaction'
                }

                parsed_transactions.append(tx_info)

            except Exception as e:
                logger.error(f"Failed to parse EVM transaction: {e}")
                continue

        return parsed_transactions

    def _parse_cosmos_transactions(self, cosmos_txs: List[Dict], user_address: str) -> List[Dict[str, Any]]:
        """
        Parse Cosmos SDK transaction format into standardized format

        Args:
            cosmos_txs: List of raw Cosmos transactions
            user_address: The address we're fetching transactions for

        Returns:
            List of parsed transaction dictionaries
        """
        parsed_transactions = []

        for cosmos_tx in cosmos_txs:
            try:
                # Extract basic transaction info
                tx_hash = cosmos_tx.get('hash', '')
                tx_height = cosmos_tx.get('height', '0')
                tx_result = cosmos_tx.get('tx_result', {})
                tx_data = cosmos_tx.get('tx', '')

                # Parse timestamp from block (may need to fetch block info)
                timestamp = self._get_block_timestamp(tx_height)

                # Decode transaction data if base64 encoded
                if isinstance(tx_data, str):
                    try:
                        decoded_tx = base64.b64decode(tx_data)
                        # Note: This would need proper protobuf decoding for full parsing
                        # For now, we'll extract what we can from events
                    except Exception as e:
                        logger.warning(f"Failed to decode tx data: {e}")

                # Extract transaction details from events
                events = tx_result.get('events', [])
                tx_info = self._extract_transaction_info(events, user_address, tx_hash)

                if tx_info:
                    tx_info.update({
                        'hash': tx_hash,
                        'height': tx_height,
                        'timestamp': timestamp,
                        'success': tx_result.get('code', 1) == 0,  # code 0 means success
                        'gas_used': tx_result.get('gas_used', '0'),
                        'gas_wanted': tx_result.get('gas_wanted', '0'),
                    })
                    parsed_transactions.append(tx_info)

            except Exception as e:
                logger.error(f"Failed to parse transaction: {e}")
                continue

        return parsed_transactions

    def _get_block_timestamp(self, height: str) -> str:
        """Get block timestamp for a given height"""
        try:
            resp = requests.get(f"{self.node_url}/block?height={height}", timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                return data.get('result', {}).get('block', {}).get('header', {}).get('time', '')
        except Exception as e:
            logger.warning(f"Failed to get block timestamp for height {height}: {e}")

        return datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')

    def _extract_transaction_info(self, events: List[Dict], user_address: str, tx_hash: str) -> Optional[Dict[str, Any]]:
        """
        Extract transaction information from Cosmos SDK events

        Args:
            events: List of transaction events
            user_address: Address we're analyzing for
            tx_hash: Transaction hash

        Returns:
            Parsed transaction info or None
        """
        tx_info = {
            'type': 'unknown',
            'from_address': '',
            'to_address': '',
            'amount': '0',
            'denom': self.native_currency.lower(),
            'fee': '0',
            'memo': ''
        }

        for event in events:
            event_type = event.get('type', '')
            attributes = event.get('attributes', [])

            # Convert attributes to dict for easier access
            attr_dict = {}
            for attr in attributes:
                key = attr.get('key', '')
                value = attr.get('value', '')
                # Handle base64 encoded attributes
                try:
                    if key:
                        decoded_key = base64.b64decode(key).decode('utf-8') if key else key
                        decoded_value = base64.b64decode(value).decode('utf-8') if value else value
                        attr_dict[decoded_key] = decoded_value
                except:
                    attr_dict[key] = value

            # Parse different event types
            if event_type == 'transfer':
                # Standard token transfer
                recipient = attr_dict.get('recipient', '')
                sender = attr_dict.get('sender', '')
                amount = attr_dict.get('amount', '0')

                # Extract amount and denom (format: "1000000uCTR")
                if amount and amount != '0':
                    # Parse amount like "1000000uCTR"
                    import re
                    match = re.match(r'(\d+)([a-zA-Z]+)', amount)
                    if match:
                        amount_value, denom = match.groups()
                        tx_info['amount'] = amount_value
                        tx_info['denom'] = denom

                tx_info['from_address'] = sender
                tx_info['to_address'] = recipient
                tx_info['type'] = 'MsgSend'

            elif event_type == 'message':
                # Message type information
                action = attr_dict.get('action', '')
                sender = attr_dict.get('sender', '')
                if action:
                    tx_info['type'] = action
                if sender:
                    tx_info['from_address'] = sender

            elif event_type == 'withdraw_rewards':
                # Staking rewards
                validator = attr_dict.get('validator', '')
                amount = attr_dict.get('amount', '0')
                tx_info['type'] = 'MsgWithdrawDelegatorReward'
                tx_info['to_address'] = user_address  # User receives rewards
                tx_info['amount'] = amount.replace(self.native_currency.lower(), '') if amount else '0'

            elif event_type == 'delegate':
                # Delegation
                validator = attr_dict.get('validator', '')
                amount = attr_dict.get('amount', '0')
                tx_info['type'] = 'MsgDelegate'
                tx_info['from_address'] = user_address
                tx_info['to_address'] = validator
                tx_info['amount'] = amount.replace(self.native_currency.lower(), '') if amount else '0'

            elif event_type == 'unbond':
                # Undelegation
                validator = attr_dict.get('validator', '')
                amount = attr_dict.get('amount', '0')
                tx_info['type'] = 'MsgUndelegate'
                tx_info['from_address'] = validator
                tx_info['to_address'] = user_address
                tx_info['amount'] = amount.replace(self.native_currency.lower(), '') if amount else '0'

        # Only return transaction info if we found relevant data
        if tx_info['type'] != 'unknown' or tx_info['amount'] != '0':
            return tx_info

        return None

# Service instance
taxbit_service = TaxBitService()