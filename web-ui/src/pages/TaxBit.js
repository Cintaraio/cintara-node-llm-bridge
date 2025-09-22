import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { useApi } from '../context/ApiContext';
import { Download, Search, Calendar, Filter, AlertCircle, CheckCircle, DollarSign, ArrowRight } from 'lucide-react';

const Container = styled.div`
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
`;

const Header = styled.div`
  margin-bottom: 2rem;
`;

const Title = styled.h1`
  font-size: 2.5rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0 0 0.5rem 0;
  display: flex;
  align-items: center;
  gap: 0.75rem;

  &::before {
    content: '🎯';
    font-size: 2rem;
  }
`;

const Subtitle = styled.p`
  color: #7d8590;
  font-size: 1.1rem;
  margin: 0;
`;

const FormContainer = styled.div`
  background: #21262d;
  border: 1px solid #30363d;
  border-radius: 12px;
  padding: 2rem;
  margin-bottom: 2rem;
`;

const FormGrid = styled.div`
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.5rem;

  @media (min-width: 768px) {
    grid-template-columns: 2fr 1fr 1fr;
  }
`;

const FormGroup = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
`;

const Label = styled.label`
  font-weight: 600;
  color: #f0f6fc;
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
`;

const Input = styled.input`
  padding: 0.75rem;
  background: #0d1117;
  border: 2px solid #30363d;
  border-radius: 8px;
  color: #f0f6fc;
  font-size: 1rem;
  transition: border-color 0.2s ease;

  &:focus {
    outline: none;
    border-color: #1f6feb;
  }

  &::placeholder {
    color: #7d8590;
  }

  &.error {
    border-color: #f85149;
  }
`;

const Select = styled.select`
  padding: 0.75rem;
  background: #0d1117;
  border: 2px solid #30363d;
  border-radius: 8px;
  color: #f0f6fc;
  font-size: 1rem;
  cursor: pointer;

  &:focus {
    outline: none;
    border-color: #1f6feb;
  }

  option {
    background: #0d1117;
    color: #f0f6fc;
  }
`;

const ButtonGroup = styled.div`
  display: flex;
  gap: 1rem;
  margin-top: 1rem;

  @media (max-width: 768px) {
    flex-direction: column;
  }
`;

const Button = styled.button`
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 1rem;

  &.primary {
    background: #238636;
    color: white;

    &:hover:not(:disabled) {
      background: #2ea043;
    }
  }

  &.secondary {
    background: #21262d;
    color: #f0f6fc;
    border: 1px solid #30363d;

    &:hover:not(:disabled) {
      background: #30363d;
    }
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  svg {
    width: 18px;
    height: 18px;
  }
`;

const ResultsContainer = styled.div`
  background: #21262d;
  border: 1px solid #30363d;
  border-radius: 12px;
  overflow: hidden;
`;

const ResultsHeader = styled.div`
  background: #161b22;
  padding: 1.5rem;
  border-bottom: 1px solid #30363d;
`;

const ResultsTitle = styled.h3`
  color: #f0f6fc;
  margin: 0 0 1rem 0;
  font-size: 1.25rem;
`;

const StatsGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
`;

const StatCard = styled.div`
  background: #0d1117;
  padding: 1rem;
  border-radius: 8px;
  text-align: center;
`;

const StatValue = styled.div`
  font-size: 1.5rem;
  font-weight: 700;
  color: #1f6feb;
  margin-bottom: 0.25rem;
`;

const StatLabel = styled.div`
  font-size: 0.75rem;
  color: #7d8590;
  text-transform: uppercase;
  letter-spacing: 0.05em;
`;

const TransactionList = styled.div`
  padding: 1.5rem;
`;

const TransactionItem = styled.div`
  background: #0d1117;
  border: 1px solid #30363d;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1rem;

  &:last-child {
    margin-bottom: 0;
  }
`;

const TransactionHeader = styled.div`
  display: flex;
  justify-content: between;
  align-items: center;
  margin-bottom: 1rem;
  flex-wrap: wrap;
  gap: 0.5rem;
`;

const TransactionHash = styled.div`
  font-family: 'Monaco', 'Menlo', monospace;
  font-size: 0.875rem;
  color: #1f6feb;
  word-break: break-all;
  flex: 1;
`;

const TransactionStatus = styled.div`
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  color: ${props => props.success ? '#3fb950' : '#f85149'};
`;

const AddressFlow = styled.div`
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 1rem;
  align-items: center;
  margin: 1rem 0;

  @media (max-width: 768px) {
    grid-template-columns: 1fr;
    text-align: center;
  }
`;

const Address = styled.div`
  font-family: 'Monaco', 'Menlo', monospace;
  font-size: 0.75rem;
  color: #7d8590;
  word-break: break-all;
  padding: 0.5rem;
  background: #161b22;
  border-radius: 4px;
`;

const Arrow = styled.div`
  color: #1f6feb;
  font-weight: bold;
  text-align: center;

  @media (max-width: 768px) {
    transform: rotate(90deg);
  }
`;

const TransactionDetails = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
`;

const DetailItem = styled.div`
  background: #161b22;
  padding: 0.75rem;
  border-radius: 6px;
`;

const DetailLabel = styled.div`
  font-size: 0.75rem;
  color: #7d8590;
  margin-bottom: 0.25rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
`;

const DetailValue = styled.div`
  color: #f0f6fc;
  font-weight: 600;
`;

const LoadingSpinner = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 3rem;
  color: #7d8590;
`;

const ErrorMessage = styled.div`
  background: #7f1d1d;
  border: 1px solid #f85149;
  border-radius: 8px;
  padding: 1rem;
  color: #fecaca;
  margin: 1rem 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;
`;

const InfoMessage = styled.div`
  background: #1f2937;
  border: 1px solid #1f6feb;
  border-radius: 8px;
  padding: 1rem;
  color: #7dd3fc;
  margin: 1rem 0;
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
`;

const EmptyState = styled.div`
  text-align: center;
  padding: 3rem;
  color: #7d8590;
`;

const TaxBit = () => {
  const { loading, error, setError, previewTaxBit, exportTaxBit } = useApi();

  const [formData, setFormData] = useState({
    address: '0x400d4a7c9df0b8f438e819b91f7d76b4ed27ce1c',
    startDate: '',
    endDate: '',
    limit: '25'
  });

  const [results, setResults] = useState(null);
  const [validationErrors, setValidationErrors] = useState({});
  const [isExporting, setIsExporting] = useState(false);

  // Set default date range (last 30 days)
  useEffect(() => {
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    setFormData(prev => ({
      ...prev,
      startDate: thirtyDaysAgo.toISOString().slice(0, 16),
      endDate: now.toISOString().slice(0, 16)
    }));
  }, []);

  const validateAddress = (address) => {
    if (!address) return false;

    // EVM address validation (0x + 40 hex chars)
    const evmPattern = /^0x[a-fA-F0-9]{40}$/;

    // Cosmos address validation (cintara + bech32)
    const cosmosPattern = /^cintara1[a-z0-9]{38,}$/;

    return evmPattern.test(address) || cosmosPattern.test(address);
  };

  const handleInputChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));

    // Clear validation errors when user starts typing
    if (validationErrors[field]) {
      setValidationErrors(prev => ({
        ...prev,
        [field]: null
      }));
    }

    // Clear API errors
    setError(null);
  };

  const validateForm = () => {
    const errors = {};

    if (!validateAddress(formData.address)) {
      errors.address = 'Please enter a valid Cintara address (EVM: 0x... or Cosmos: cintara1...)';
    }

    if (formData.startDate && formData.endDate) {
      const start = new Date(formData.startDate);
      const end = new Date(formData.endDate);

      if (start >= end) {
        errors.endDate = 'End date must be after start date';
      }
    }

    setValidationErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handlePreview = async () => {
    if (!validateForm()) return;

    try {
      const params = {
        limit: parseInt(formData.limit)
      };

      if (formData.startDate) {
        params.start_date = new Date(formData.startDate).toISOString();
      }

      if (formData.endDate) {
        params.end_date = new Date(formData.endDate).toISOString();
      }

      const data = await previewTaxBit(formData.address, params);
      setResults(data);
    } catch (err) {
      console.error('Preview failed:', err);
    }
  };

  const handleExport = async () => {
    if (!validateForm()) return;

    setIsExporting(true);
    try {
      const params = {};

      if (formData.startDate) {
        params.start_date = new Date(formData.startDate).toISOString();
      }

      if (formData.endDate) {
        params.end_date = new Date(formData.endDate).toISOString();
      }

      await exportTaxBit(formData.address, params);
    } catch (err) {
      console.error('Export failed:', err);
    } finally {
      setIsExporting(false);
    }
  };

  const renderTransaction = (tx, index) => (
    <TransactionItem key={tx.txid || index}>
      <TransactionHeader>
        <TransactionHash>
          🔗 {tx.txid || 'Unknown Hash'}
        </TransactionHash>
        <TransactionStatus success={tx.status === 'Completed'}>
          {tx.status === 'Completed' ? <CheckCircle /> : <AlertCircle />}
          {tx.status || 'Unknown'}
        </TransactionStatus>
      </TransactionHeader>

      <AddressFlow>
        <Address>
          <DetailLabel>From</DetailLabel>
          {tx.from_wallet_address || 'N/A'}
        </Address>
        <Arrow>
          <ArrowRight />
        </Arrow>
        <Address>
          <DetailLabel>To</DetailLabel>
          {tx.to_wallet_address || 'N/A'}
        </Address>
      </AddressFlow>

      <TransactionDetails>
        <DetailItem>
          <DetailLabel>Amount</DetailLabel>
          <DetailValue>
            {tx.amount_display || `${tx.in_amount || tx.out_amount || '0'} ${tx.in_currency || tx.out_currency || 'CINT'}`}
          </DetailValue>
        </DetailItem>
        <DetailItem>
          <DetailLabel>Category</DetailLabel>
          <DetailValue>{tx.category || 'Unknown'}</DetailValue>
        </DetailItem>
        <DetailItem>
          <DetailLabel>Type</DetailLabel>
          <DetailValue>{tx.transaction_type || 'Unknown'}</DetailValue>
        </DetailItem>
        <DetailItem>
          <DetailLabel>Source</DetailLabel>
          <DetailValue>{tx.database_source || 'N/A'}</DetailValue>
        </DetailItem>
        <DetailItem>
          <DetailLabel>Timestamp</DetailLabel>
          <DetailValue>{tx.timestamp ? new Date(tx.timestamp).toLocaleString() : 'N/A'}</DetailValue>
        </DetailItem>
        <DetailItem>
          <DetailLabel>Fee</DetailLabel>
          <DetailValue>{tx.fee || '0'} {tx.fee_currency || 'CINT'}</DetailValue>
        </DetailItem>
      </TransactionDetails>
    </TransactionItem>
  );

  return (
    <Container>
      <Header>
        <Title>TaxBit Export</Title>
        <Subtitle>
          Export transaction data with production LevelDB integration for tax compliance
        </Subtitle>
      </Header>

      <FormContainer>
        <FormGrid>
          <FormGroup>
            <Label>Wallet Address</Label>
            <Input
              type="text"
              value={formData.address}
              onChange={(e) => handleInputChange('address', e.target.value)}
              placeholder="Enter address (0x... or cintara1...)"
              className={validationErrors.address ? 'error' : ''}
            />
            {validationErrors.address && (
              <ErrorMessage>
                <AlertCircle />
                {validationErrors.address}
              </ErrorMessage>
            )}
          </FormGroup>

          <FormGroup>
            <Label>Start Date (Optional)</Label>
            <Input
              type="datetime-local"
              value={formData.startDate}
              onChange={(e) => handleInputChange('startDate', e.target.value)}
            />
          </FormGroup>

          <FormGroup>
            <Label>End Date (Optional)</Label>
            <Input
              type="datetime-local"
              value={formData.endDate}
              onChange={(e) => handleInputChange('endDate', e.target.value)}
              className={validationErrors.endDate ? 'error' : ''}
            />
            {validationErrors.endDate && (
              <ErrorMessage>
                <AlertCircle />
                {validationErrors.endDate}
              </ErrorMessage>
            )}
          </FormGroup>
        </FormGrid>

        <FormGroup style={{ marginTop: '1rem' }}>
          <Label>Preview Limit</Label>
          <Select
            value={formData.limit}
            onChange={(e) => handleInputChange('limit', e.target.value)}
          >
            <option value="10">10 transactions</option>
            <option value="25">25 transactions</option>
            <option value="50">50 transactions</option>
          </Select>
        </FormGroup>

        <ButtonGroup>
          <Button
            className="primary"
            onClick={handlePreview}
            disabled={loading}
          >
            <Search />
            {loading ? 'Searching...' : 'Preview Transactions'}
          </Button>
          <Button
            className="secondary"
            onClick={handleExport}
            disabled={isExporting || !formData.address}
          >
            <Download />
            {isExporting ? 'Exporting...' : 'Export CSV'}
          </Button>
        </ButtonGroup>
      </FormContainer>

      {error && (
        <ErrorMessage>
          <AlertCircle />
          {error}
        </ErrorMessage>
      )}

      <InfoMessage>
        <DollarSign />
        <div>
          <strong>Enhanced Features:</strong> This interface uses production LevelDB integration
          to access real transaction data from the 1.6GB Cintara database. Supports both
          Cosmos (cintara1...) and EVM (0x...) address formats with optimized performance.
        </div>
      </InfoMessage>

      {results && (
        <ResultsContainer>
          <ResultsHeader>
            <ResultsTitle>Transaction Results</ResultsTitle>
            <StatsGrid>
              <StatCard>
                <StatValue>{results.search_summary?.total_found || 0}</StatValue>
                <StatLabel>Total Found</StatLabel>
              </StatCard>
              <StatCard>
                <StatValue>{results.search_summary?.preview_count || 0}</StatValue>
                <StatLabel>Previewing</StatLabel>
              </StatCard>
              <StatCard>
                <StatValue>{results.search_summary?.successful_conversions || 0}</StatValue>
                <StatLabel>Converted</StatLabel>
              </StatCard>
              <StatCard>
                <StatValue>
                  {results.search_summary?.database_performance?.includes('✅') ? '✅' : '⚠️'}
                </StatValue>
                <StatLabel>DB Status</StatLabel>
              </StatCard>
            </StatsGrid>
          </ResultsHeader>

          <TransactionList>
            {results.transactions && results.transactions.length > 0 ? (
              results.transactions.map(renderTransaction)
            ) : (
              <EmptyState>
                <AlertCircle size={48} />
                <p>No transactions found for this address and date range.</p>
                <p>Try adjusting the date range or check the address format.</p>
              </EmptyState>
            )}
          </TransactionList>
        </ResultsContainer>
      )}

      {loading && !results && (
        <LoadingSpinner>
          <Search size={24} />
          <span style={{ marginLeft: '0.5rem' }}>Scanning 1.6GB LevelDB database...</span>
        </LoadingSpinner>
      )}
    </Container>
  );
};

export default TaxBit;