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
from datetime import datetime, timezone
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
    
    def __init__(self):
        self.native_currency = "CTR"  # Cintara native token
        
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
        # TODO: Query transactions from database
        # This is a placeholder - needs to be connected to actual indexer DB
        
        sample_transactions = [
            {
                'hash': 'ABC123',
                'timestamp': datetime.now(timezone.utc),
                'from_address': address,
                'to_address': 'cintara1recipient...',
                'amount': '1000000',
                'denom': 'uCTR',
                'fee': '5000',
                'type': 'MsgSend',
                'success': True,
                'memo': 'Sample transaction'
            }
        ]
        
        # Convert transactions
        taxbit_transactions = []
        for tx_data in sample_transactions:
            try:
                taxbit_tx = self.convert_transaction(tx_data)
                taxbit_transactions.append(taxbit_tx)
            except Exception as e:
                logger.error(f"Failed to convert transaction {tx_data.get('hash')}: {e}")
                
        # Generate CSV
        return self.generate_csv(taxbit_transactions)

# Service instance
taxbit_service = TaxBitService()