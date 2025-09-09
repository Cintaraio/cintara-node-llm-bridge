import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import StatusCard from '../components/StatusCard';
import { useApi } from '../context/ApiContext';
import { RefreshCw } from 'lucide-react';

const Container = styled.div`
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
`;

const Header = styled.div`
  display: flex;
  justify-content: between;
  align-items: center;
  margin-bottom: 2rem;
`;

const Title = styled.h1`
  font-size: 2rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0;
`;

const RefreshButton = styled.button`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: #21262d;
  border: 1px solid #30363d;
  border-radius: 6px;
  color: #f0f6fc;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-left: auto;

  &:hover {
    background: #30363d;
    border-color: #58a6ff;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  svg {
    width: 16px;
    height: 16px;
    ${props => props.spinning ? 'animation: spin 1s linear infinite;' : ''}
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
`;

const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
`;

const ErrorMessage = styled.div`
  background: #7f1d1d;
  border: 1px solid #f87171;
  border-radius: 6px;
  padding: 1rem;
  color: #fecaca;
  margin-bottom: 1rem;
`;

const Dashboard = () => {
  const { 
    loading, 
    error,
    checkHealth, 
    getNodeStatus,
    diagnoseNode,
    getNodePeers
  } = useApi();

  const [healthData, setHealthData] = useState(null);
  const [nodeData, setNodeData] = useState(null);
  const [diagnosticsData, setDiagnosticsData] = useState(null);
  const [peerData, setPeerData] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  const fetchAllData = async () => {
    setRefreshing(true);
    
    try {
      // Fetch health status
      const health = await checkHealth();
      setHealthData(health);

      // Fetch node status
      try {
        const node = await getNodeStatus();
        setNodeData(node);
      } catch (err) {
        console.warn('Node status fetch failed:', err.message);
      }

      // Fetch diagnostics
      try {
        const diagnostics = await diagnoseNode();
        setDiagnosticsData(diagnostics);
      } catch (err) {
        console.warn('Diagnostics fetch failed:', err.message);
      }

      // Fetch peer data
      try {
        const peers = await getNodePeers();
        setPeerData(peers);
      } catch (err) {
        console.warn('Peer data fetch failed:', err.message);
      }
    } catch (err) {
      console.error('Failed to fetch dashboard data:', err);
    } finally {
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchAllData();
    
    // Auto refresh every 30 seconds
    const interval = setInterval(fetchAllData, 30000);
    return () => clearInterval(interval);
  }, []);

  const getHealthMetrics = () => {
    if (!healthData) return [];
    
    return [
      { label: 'LLM Server', value: healthData.components?.llm_server || 'unknown' },
      { label: 'Blockchain Node', value: healthData.components?.blockchain_node || 'unknown' },
      { label: 'Last Update', value: new Date(healthData.timestamp).toLocaleTimeString() }
    ];
  };

  const getNodeMetrics = () => {
    if (!nodeData?.details) return [];
    
    return [
      { label: 'Block Height', value: nodeData.details.latest_block_height || '0' },
      { label: 'Network', value: nodeData.details.network || 'unknown' },
      { label: 'Catching Up', value: nodeData.details.catching_up ? 'Yes' : 'No' },
      { label: 'Moniker', value: nodeData.details.moniker || 'unknown' }
    ];
  };

  const getDiagnosticsMetrics = () => {
    if (!diagnosticsData?.diagnosis) return [];
    
    const diagnosis = diagnosticsData.diagnosis;
    return [
      { label: 'Health Score', value: diagnosis.health_score || 'unknown' },
      { label: 'Issues Found', value: diagnosis.issues?.length || 0 },
      { label: 'Analysis Time', value: `${diagnosticsData.latency_ms}ms` }
    ];
  };

  const getPeerMetrics = () => {
    if (!peerData) return [];
    
    return [
      { label: 'Total Peers', value: peerData.total_peers || 0 },
      { label: 'Connectivity', value: peerData.peer_analysis?.connectivity_health || 'unknown' },
      { label: 'Diversity', value: peerData.peer_analysis?.peer_diversity || 'unknown' },
      { label: 'Listening', value: peerData.listening ? 'Yes' : 'No' }
    ];
  };

  return (
    <Container>
      <Header>
        <Title>Dashboard</Title>
        <RefreshButton 
          onClick={fetchAllData} 
          disabled={refreshing}
          spinning={refreshing}
        >
          <RefreshCw />
          {refreshing ? 'Refreshing...' : 'Refresh'}
        </RefreshButton>
      </Header>

      {error && (
        <ErrorMessage>
          Error: {error}
        </ErrorMessage>
      )}

      <Grid>
        <StatusCard
          title="System Health"
          status={healthData?.status}
          description="Overall system status including LLM server and blockchain node connectivity"
          metrics={getHealthMetrics()}
          loading={loading && !healthData}
        />

        <StatusCard
          title="Node Status"
          status={nodeData?.details?.catching_up ? 'syncing' : 'synced'}
          description="Cintara blockchain node synchronization and network status"
          metrics={getNodeMetrics()}
          loading={loading && !nodeData}
        />

        <StatusCard
          title="AI Diagnostics"
          status={diagnosticsData?.diagnosis?.health_score}
          description="AI-powered analysis of node health and performance"
          metrics={getDiagnosticsMetrics()}
          loading={loading && !diagnosticsData}
        />

        <StatusCard
          title="Network Peers"
          status={peerData?.peer_analysis?.connectivity_health}
          description="Peer connectivity and network health analysis"
          metrics={getPeerMetrics()}
          loading={loading && !peerData}
        />
      </Grid>
    </Container>
  );
};

export default Dashboard;